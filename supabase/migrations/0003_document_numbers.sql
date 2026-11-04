-- Belge numaraları: DE-YYYY-0001 (devis), BC-YYYY-0001 (bon de commande), FA-YYYY-0001 (fatura, şirket önekiyle)
create or replace function public.documents_set_number() returns trigger
language plpgsql set search_path = public as $$
declare n int; y text := to_char(coalesce(new.issue_date, current_date),'YYYY'); p text;
begin
  if new.number is null then
    if new.kind = 'invoice' then
      select coalesce(invoice_prefix,'FA') into p from companies where id = new.company_id;
    elsif new.kind = 'order' then p := 'BC';
    else p := 'DE'; end if;
    perform pg_advisory_xact_lock(hashtext(new.company_id::text || new.kind::text || y));
    select count(*)+1 into n from documents where company_id = new.company_id and kind = new.kind and number like p||'-'||y||'-%';
    new.number := p||'-'||y||'-'||lpad(n::text,4,'0');
  end if;
  return new;
end $$;
create trigger documents_number before insert on public.documents for each row execute function public.documents_set_number();

-- Satırlardan toplamları hesapla
create or replace function public.documents_recalc() returns trigger
language plpgsql set search_path = public as $$
declare d uuid := coalesce(new.document_id, old.document_id);
begin
  update documents set
    total_ht  = coalesce((select round(sum(quantity*unit_price),2) from document_lines where document_id = d),0),
    total_tva = coalesce((select round(sum(quantity*unit_price*vat_rate/100),2) from document_lines where document_id = d),0)
  where id = d;
  update documents set total_ttc = total_ht + total_tva where id = d;
  return null;
end $$;
create trigger document_lines_recalc after insert or update or delete on public.document_lines
  for each row execute function public.documents_recalc();

-- Faturalar silinemez (Fransız mevzuatı: boşluksuz numaralandırma)
create policy "no delete invoices" on public.documents as restrictive for delete using (kind <> 'invoice');
