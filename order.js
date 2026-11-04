// Hızlı bon de commande: müşteri → satırlar → e-posta seçimi → kaydet + PDF
(function(){
const $=id=>document.getElementById(id);
let customers=[],products=[],lines=[],company=null;
const eur=n=>(Math.round(n*100)/100).toLocaleString('fr-FR',{minimumFractionDigits:2,maximumFractionDigits:2})+' €';

window.openOrder=async function(){
  show('s-order');lines=[];
  const [c,p,co]=await Promise.all([
    sb.from('customers').select('id,name,emails,address').order('name'),
    sb.from('products').select('id,name,unit,unit_price,vat_rate').eq('active',true).order('name'),
    sb.from('companies').select('*').eq('id',companyId).single()]);
  customers=c.data||[];products=p.data||[];company=co.data;
  $('o-customer').innerHTML=`<option value="">— ${esc(T('choose_customer'))} —</option>`+customers.map(x=>`<option value="${x.id}">${esc(x.name)}</option>`).join('');
  $('o-product').innerHTML=`<option value="">— ${esc(T('choose_product'))} —</option>`+products.map(x=>`<option value="${x.id}">${esc(x.name)} (${eur(x.unit_price)}/${esc(x.unit)})</option>`).join('');
  $('o-qty').value='1';$('o-msg').textContent='';render();
};
function render(){
  const cu=customers.find(x=>x.id===$('o-customer').value);
  $('o-emails').innerHTML=cu&&cu.emails.length?cu.emails.map((e,i)=>`<label class="chk"><input type="checkbox" value="${esc(e)}" ${i===0?'checked':''}> ${esc(e)}</label>`).join(''):'';
  let ht=0,tva=0;
  $('o-lines').innerHTML=lines.map((l,i)=>{const t=l.quantity*l.unit_price;ht+=t;tva+=t*l.vat_rate/100;
    return `<li><b>${esc(l.label)}</b> <button type="button" class="x" data-i="${i}">✕</button><small>${l.quantity} ${esc(l.unit)} × ${eur(l.unit_price)} = ${eur(t)}</small></li>`}).join('');
  $('o-total').innerHTML=lines.length?`HT ${eur(ht)} · TVA ${eur(tva)}<br><b>${esc(T('total'))} TTC ${eur(ht+tva)}</b>`:'';
  $('o-lines').querySelectorAll('.x').forEach(b=>b.onclick=()=>{lines.splice(+b.dataset.i,1);render()});
}
$('o-customer').onchange=render;
$('o-add').onclick=()=>{
  const p=products.find(x=>x.id===$('o-product').value);const q=parseFloat($('o-qty').value.replace(',','.'));
  if(!p||!(q>0))return;
  lines.push({product_id:p.id,label:p.name,unit:p.unit,quantity:q,unit_price:Number(p.unit_price),vat_rate:Number(p.vat_rate)});
  $('o-product').value='';$('o-qty').value='1';render();
};
$('o-send').onclick=async()=>{
  const cu=customers.find(x=>x.id===$('o-customer').value),msg=$('o-msg');
  if(!cu||!lines.length){msg.className='msg bad';msg.textContent=T('choose_customer');return}
  const to=[...$('o-emails').querySelectorAll('input:checked')].map(x=>x.value);
  $('o-send').disabled=true;
  try{
    const {data:doc,error}=await sb.from('documents').insert({company_id:companyId,kind:'order',customer_id:cu.id,sent_to:to,status:'sent',sent_at:new Date().toISOString()}).select().single();
    if(error)throw error;
    const {error:e2}=await sb.from('document_lines').insert(lines.map((l,i)=>({...l,company_id:companyId,document_id:doc.id,position:i})));
    if(e2)throw e2;
    const blob=makePdf(doc,cu,lines);
    await deliver(blob,doc.number+'.pdf',to,doc.number);
    msg.className='msg ok';msg.textContent=T('sent')+' '+doc.number;lines=[];render();
  }catch(e){msg.className='msg bad';msg.textContent=T('error')+' ('+(e.message||e)+')'}
  $('o-send').disabled=false;
};

// PDF her zaman Fransızca (yasal belge)
window.makePdf=function(doc,cu,lines){
  const {jsPDF}=window.jspdf;const pdf=new jsPDF({unit:'mm',format:'a4'});
  const c=company||{};let y=20;
  pdf.setFontSize(18);pdf.setFont('helvetica','bold');pdf.text(c.name||'',15,y);
  pdf.setFontSize(9);pdf.setFont('helvetica','normal');
  [c.address,c.siret&&('SIRET '+c.siret),c.tva_number&&('TVA '+c.tva_number),c.email,c.phone].filter(Boolean).forEach(t=>{y+=5;pdf.text(String(t),15,y)});
  pdf.setFontSize(16);pdf.setFont('helvetica','bold');pdf.text('BON DE COMMANDE',195,20,{align:'right'});
  pdf.setFontSize(10);pdf.setFont('helvetica','normal');
  pdf.text('N° '+doc.number,195,27,{align:'right'});
  pdf.text('Date : '+new Date(doc.issue_date).toLocaleDateString('fr-FR'),195,32,{align:'right'});
  y=Math.max(y,40)+10;
  pdf.setFont('helvetica','bold');pdf.text('Client',120,y);pdf.setFont('helvetica','normal');
  [cu.name,cu.address].filter(Boolean).forEach((t,i)=>pdf.text(String(t),120,y+5+i*5));
  y+=22;
  const cols=[15,105,125,145,165];
  pdf.setFillColor(37,99,235);pdf.rect(15,y-5,180,8,'F');pdf.setTextColor(255);pdf.setFont('helvetica','bold');
  ['Désignation','Qté','Unité','PU HT','Total HT'].forEach((h,i)=>pdf.text(h,i===0?cols[i]+2:(i===4?cols[i]+28:cols[i]+18),y,{align:i===0?'left':'right'}));
  pdf.setTextColor(0);pdf.setFont('helvetica','normal');y+=9;
  let ht=0,tva=0;const f=n=>(Math.round(n*100)/100).toLocaleString('fr-FR',{minimumFractionDigits:2,maximumFractionDigits:2}).replace(/[\u202f\u00a0]/g,' ');
  lines.forEach(l=>{const t=l.quantity*l.unit_price;ht+=t;tva+=t*l.vat_rate/100;
    if(y>270){pdf.addPage();y=20}
    pdf.text(pdf.splitTextToSize(l.label,85)[0],cols[0]+2,y);pdf.text(String(l.quantity),cols[1]+18,y,{align:'right'});
    pdf.text(l.unit||'',cols[2]+18,y,{align:'right'});pdf.text(f(l.unit_price),cols[3]+18,y,{align:'right'});pdf.text(f(t),cols[4]+28,y,{align:'right'});
    y+=7;pdf.setDrawColor(229);pdf.line(15,y-4,195,y-4)});
  y+=4;
  [['Total HT',ht],['TVA',tva],['Total TTC',ht+tva]].forEach(([k,v],i)=>{pdf.setFont('helvetica',i===2?'bold':'normal');pdf.text(k,150,y);pdf.text(f(v)+' EUR',195,y,{align:'right'});y+=6});
  pdf.setFontSize(8);pdf.setTextColor(120);pdf.text('Document généré par NOVA BAT',15,287);
  return pdf.output('blob');
};

// Telefonda paylaşım menüsü (e-posta uygulaması PDF ekli açılır); bilgisayarda indirme + e-posta taslağı
async function deliver(blob,name,to,number){
  const file=new File([blob],name,{type:'application/pdf'});
  if(navigator.canShare&&navigator.canShare({files:[file]})){
    try{await navigator.share({files:[file],title:'Bon de commande '+number,text:'Bonjour,\nVeuillez trouver ci-joint le bon de commande '+number+'.\nCordialement'});return}catch(e){if(e.name==='AbortError')return}
  }
  const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download=name;a.click();
  if(to.length)location.href='mailto:'+to.join(',')+'?subject='+encodeURIComponent('Bon de commande '+number)+'&body='+encodeURIComponent('Bonjour,\n\nVeuillez trouver ci-joint le bon de commande '+number+'.\n\nCordialement');
}
})();
