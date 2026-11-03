const C='nova-bat-v2';const A=['./','index.html','manifest.webmanifest','icons/icon.svg','i18n.js'];
self.addEventListener('install',e=>e.waitUntil(caches.open(C).then(c=>c.addAll(A))));
self.addEventListener('fetch',e=>e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request))));
