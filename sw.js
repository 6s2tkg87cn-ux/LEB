// Offline-Start: hält die zuletzt geladene, verschlüsselte Seite bereit. Lädt nur von der eigenen Adresse, sendet nichts.
const C = 'leb-1', HOME = new URL('./', self.location).href, ICON = new URL('apple-touch-icon.png', self.location).href;
self.addEventListener('install', e => { self.skipWaiting(); e.waitUntil(caches.open(C).then(c => c.addAll([HOME, ICON].map(u => new Request(u, {cache: 'reload'}))))) });
self.addEventListener('activate', e => e.waitUntil((async () => { for (const k of await caches.keys()) if (k.startsWith('leb-') && k !== C) await caches.delete(k); await self.clients.claim() })()));
self.addEventListener('fetch', e => {
  const r = e.request, u = r.url.split('#')[0].split('?')[0];
  if (r.method !== 'GET') return;
  if (u === ICON) { e.respondWith(caches.match(ICON).then(x => x || fetch(r))); return }
  if (r.mode !== 'navigate' || (u !== HOME && u !== HOME + 'index.html')) return;
  // Erst das Netz (höchstens 4 Sekunden), sonst die gespeicherte Seite; eine spätere Antwort wird für das nächste Mal gespeichert
  const net = fetch(HOME, {cache: 'no-cache', credentials: 'omit'}).then(async x => { if (!x.ok) throw new Error(x.status); const c = await caches.open(C); await c.put(HOME, x.clone()); return x });
  e.waitUntil(net.catch(() => {}));
  e.respondWith((async () => { const old = await caches.match(HOME); if (!old) return net;
    try { return await Promise.race([net, new Promise((_, n) => setTimeout(() => n(new Error('langsam')), 4000))]) } catch(x) { return old } })());
});
