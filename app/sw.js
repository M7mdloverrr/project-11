const V = 'quran-shell-v5';
const KEEP = [V, 'quran-audio-v1', 'quran-bg-v1', 'quran-tafsir-v1'];
const SHELL = ['./', 'index.html', 'style.css', 'js/app.js', 'js/prayer.js', 'js/studio.js', 'vendor/adhan.js',
  'assets/quran.json', 'assets/fonts/amiri_quran.ttf', 'assets/fonts/kfgqpc_hafs.ttf', 'assets/script/qpc.json',
  'assets/splash.webp', 'assets/app_bg.webp', 'assets/timing/sufi.json', 'assets/timing/mousa.json', 'manifest.webmanifest',
  'icons/icon-192.png', 'icons/icon-512.png', 'icons/apple-touch-icon.png',
  ...['waterfall', 'forest', 'ocean', 'mountains', 'rain', 'sunset'].map(b => `assets/bg/${b}.jpg`)];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(V).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => !KEEP.includes(k)).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const req = e.request;
  const url = new URL(req.url);
  if (req.method !== 'GET' || url.origin !== location.origin || req.headers.has('range')) return;
  const bg = url.pathname.endsWith('.mp4');
  const name = bg ? 'quran-bg-v1' : V;
  e.respondWith(caches.open(name).then(async c => {
    const hit = await c.match(req, { ignoreSearch: true });
    const net = fetch(req).then(r => { if (r.ok && r.status === 200) c.put(req, r.clone()); return r; });
    if (hit) { if (!bg) net.catch(() => {}); return hit; }
    return net;
  }));
});
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: 'window' }).then(ws => ws.length ? ws[0].focus() : self.clients.openWindow('./#prayer')));
});
