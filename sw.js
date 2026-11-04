const C='nova-bat-v4';const A=['./','index.html','manifest.webmanifest','icons/icon.svg','i18n.js','config.js','vendor/supabase.min.js','vendor/jspdf.umd.min.js','order.js'];
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(C).then(c=>c.addAll(A)))});
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==C).map(k=>caches.delete(k))))));
// Sadece kendi dosyalarımızı önbellekten ver; Supabase gibi dış istekler her zaman ağdan gider.
self.addEventListener('fetch',e=>{const u=new URL(e.request.url);if(u.origin!==location.origin||e.request.method!=='GET')return;
e.respondWith(fetch(e.request).then(r=>{const c=r.clone();caches.open(C).then(x=>x.put(e.request,c));return r}).catch(()=>caches.match(e.request)))});
