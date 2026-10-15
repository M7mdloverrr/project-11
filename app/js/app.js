'use strict';
const AR = v => String(v).replace(/\d/g, c => '٠١٢٣٤٥٦٧٨٩'[c]).replace('.', '٫');
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const load = (k, d) => { try { const v = JSON.parse(localStorage.getItem(k)); return v ?? d; } catch { return d; } };
const save = (k, v) => localStorage.setItem(k, JSON.stringify(v));

const ICON = {
  play: 'M8 5v14l11-7z', pause: 'M6 19h4V5H6v14zm8-14v14h4V5h-4z', stop: 'M6 6h12v12H6z',
  next: 'M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z', prev: 'M6 6h2v12H6zm3.5 6l8.5 6V6z',
  bm: 'M17 3H7c-1.1 0-2 .9-2 2v16l7-3 7 3V5c0-1.1-.9-2-2-2z',
  bmo: 'M17 3H7c-1.1 0-1.99.9-1.99 2L5 21l7-3 7 3V5c0-1.1-.9-2-2-2zm0 15l-5-2.18L7 18V5h10v13z',
  back: 'M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8z',
  chr: 'M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z', chl: 'M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z',
  settings: 'M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58a.49.49 0 00.12-.61l-1.92-3.32a.488.488 0 00-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54a.484.484 0 00-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58a.49.49 0 00-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z',
  download: 'M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM17 13l-5 5-5-5h3V9h4v4h3z',
  clock: 'M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z',
  compass: 'M12 10.9c-.61 0-1.1.49-1.1 1.1s.49 1.1 1.1 1.1c.61 0 1.1-.49 1.1-1.1s-.49-1.1-1.1-1.1zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm2.19 12.19L6 18l3.81-8.19L18 6l-3.81 8.19z',
  movie: 'M18 4l2 4h-3l-2-4h-2l2 4h-3l-2-4H8l2 4H7L5 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V4h-4z',
  share: 'M18 16.08c-.76 0-1.44.3-1.96.77L8.91 12.7c.05-.23.09-.46.09-.7s-.04-.47-.09-.7l7.05-4.11c.54.5 1.25.81 2.04.81 1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3c0 .24.04.47.09.7L8.04 9.81C7.5 9.31 6.79 9 6 9c-1.66 0-3 1.34-3 3s1.34 3 3 3c.79 0 1.5-.31 2.04-.81l7.12 4.16c-.05.21-.08.43-.08.65 0 1.61 1.31 2.92 2.92 2.92s2.92-1.31 2.92-2.92-1.31-2.92-2.92-2.92z',
  repeat: 'M7 7h10v3l4-4-4-4v3H5v6h2V7zm10 10H7v-3l-4 4 4 4v-3h12v-6h-2v4z',
  close: 'M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z',
  book: 'M21 5c-1.11-.35-2.33-.5-3.5-.5-1.95 0-4.05.4-5.5 1.5-1.45-1.1-3.55-1.5-5.5-1.5S2.45 4.9 1 6v14.65c0 .25.25.5.5.5.1 0 .15-.05.25-.05C3.1 20.45 5.05 20 6.5 20c1.95 0 4.05.4 5.5 1.5 1.35-.85 3.8-1.5 5.5-1.5 1.65 0 3.35.3 4.75 1.05.1.05.15.05.25.05.25 0 .5-.25.5-.5V6c-.6-.45-1.25-.75-2-1zm0 13.5c-1.1-.35-2.3-.5-3.5-.5-1.7 0-4.15.65-5.5 1.5V8c1.35-.85 3.8-1.5 5.5-1.5 1.2 0 2.4.15 3.5.5v11.5z',
  pin: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
  del: 'M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z',
  check: 'M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z',
  plus: 'M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z', minus: 'M19 13H5v-2h14v2z',
  upload: 'M18 15v3H6v-3H4v3c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2v-3h-2zM7 9l1.41 1.41L11 7.83V16h2V7.83l2.59 2.58L17 9l-5-5-5 5z',
};
const ic = (n, cls = '') => `<svg class="ic ${cls}" viewBox="0 0 24 24" aria-hidden="true"><path d="${ICON[n]}"/></svg>`;

const RECITERS = [
  { id: 'maher', ar: 'ماهر المعيقلي', f: 'MaherAlMuaiqly128kbps' },
  { id: 'alafasy', ar: 'مشاري العفاسي', f: 'Alafasy_128kbps' },
  { id: 'sudais', ar: 'عبد الرحمن السديس', f: 'Abdurrahmaan_As-Sudais_192kbps' },
  { id: 'basit', ar: 'عبد الباسط عبد الصمد', f: 'Abdul_Basit_Murattal_192kbps' },
  { id: 'minshawi', ar: 'محمد صديق المنشاوي', f: 'Minshawy_Murattal_128kbps' },
];
const rec = id => RECITERS.find(r => r.id === id) || RECITERS[0];
const pad3 = n => String(n).padStart(3, '0');
const audioUrl = (r, s, a) => `https://everyayah.com/data/${rec(r).f}/${pad3(s)}${pad3(a)}.mp3`;
const AC = 'quran-audio-v1';

const DEF = { theme: 'system', pageStyle: 0, font: 28, line: 1.9, reciter: 'maher', speed: 1, repeat: 1, continuous: true, follow: true, keepPlaying: false, wake: true, method: 'MuslimWorldLeague', hanafi: false, notify: false };
const P = Object.assign({}, DEF, load('prefs', {}));
let last = load('last', { page: 1, s: 1, a: 1 });
let marks = load('marks', []);
function setP(k, v) { P[k] = v; save('prefs', P); applyTheme(); onPref(k); }

/* data */
let QD = null; const pages = []; const juzStart = [];
const ay = (s, a) => QD.surahs[s - 1].ayahs[a - 1];
const sname = s => QD.surahs[s - 1].name;
async function loadData() {
  const r = await fetch('assets/quran.json');
  if (!r.ok) throw new Error('data');
  QD = await r.json();
  for (const s of QD.surahs) s.ayahs.forEach((t, i) => {
    (pages[t[2]] ||= []).push([s.n, i + 1]);
    if (!juzStart[t[1]]) juzStart[t[1]] = { s: s.n, a: i + 1, page: t[2] };
  });
}

/* theme */
const PAGE_STYLES = ['ورق المصحف', 'كريمي', 'أخضر هادئ', 'سادة'];
const PAGE_L = [['#FBF3DF', '#1B1B18'], ['#F2E3C2', '#2A1E10'], ['#EAF4EC', '#10201A'], ['#FFFFFF', '#000000']];
const PAGE_D = [['#1E1B14', '#EFE6D2'], ['#2A2116', '#F1E2C4'], ['#0F2A21', '#E8F3EE'], ['#17201D', '#F3F3F0']];
const darkMQ = matchMedia('(prefers-color-scheme: dark)');
const isDark = () => P.theme === 'dark' || (P.theme === 'system' && darkMQ.matches);
function applyTheme() {
  const d = isDark(), root = document.documentElement, [bg, ink] = (d ? PAGE_D : PAGE_L)[P.pageStyle] || PAGE_L[0];
  root.dataset.theme = d ? 'dark' : 'light';
  root.style.setProperty('--page', bg); root.style.setProperty('--ink', ink);
  root.style.setProperty('--qfs', P.font + 'px'); root.style.setProperty('--qlh', P.line);
  $('meta[name=theme-color]').content = d ? '#050807' : '#F4F7F5';
}
darkMQ.addEventListener?.('change', applyTheme);

/* ui helpers */
function toast(msg, label, fn) {
  const t = $('#toast');
  t.innerHTML = `<span>${msg}</span>${label ? `<button>${label}</button>` : ''}`;
  if (fn) t.querySelector('button').onclick = () => { t.classList.remove('show'); fn(); };
  t.classList.add('show'); clearTimeout(t._t); t._t = setTimeout(() => t.classList.remove('show'), fn ? 7000 : 3500);
}
function modal(inner) {
  const m = document.createElement('div'); m.className = 'modal';
  m.innerHTML = `<div class="sheet">${inner}</div>`;
  m.addEventListener('click', e => { if (e.target === m || e.target.closest('[data-close]')) m.remove(); });
  document.body.append(m); return m;
}
const header = (title, sub = '', right = '<span class="ib"></span>') =>
  `<header class="hdr"><button class="ib" data-act="back" aria-label="رجوع">${ic('back')}</button><div class="rtitle"><b>${title}</b>${sub ? `<small>${sub}</small>` : ''}</div>${right}</header>`;
const sw = k => `<label class="sw"><input type="checkbox" data-sw="${k}" ${P[k] ? 'checked' : ''}><span></span></label>`;
const seg = (k, opts, cls = '') => `<div class="seg ${cls}">${opts.map(([v, l]) => `<button data-set="${k}" data-v='${JSON.stringify(v)}' class="${P[k] === v ? 'on' : ''}">${l}</button>`).join('')}</div>`;

/* router */
let route = '', inApp = 0;
const go = h => { inApp++; location.hash = h; };
function back() { if (inApp > 0 && history.length > 1) { inApp--; history.back(); } else location.hash = 'home'; }
function render() {
  const [name, arg] = (location.hash.slice(1) || 'home').split('/');
  if (route === 'read' && name !== 'read' && !P.keepPlaying) stopAudio();
  if (route === 'studio' && name !== 'studio') Studio.leave();
  if (route === 'qibla' && name !== 'qibla') Qibla.leave();
  route = name; releaseWake(); window.scrollTo(0, 0);
  const v = $('#view');
  ({ read: () => renderReader(+arg || last.page), settings: renderSettings, downloads: renderDownloads,
    prayer: () => Prayer.render(v), qibla: () => Qibla.render(v), studio: () => Studio.render(v) }[name] || renderHome)();
}
window.addEventListener('hashchange', render);

/* home */
let homeTab = 0, deferredPrompt = null;
window.addEventListener('beforeinstallprompt', e => { e.preventDefault(); deferredPrompt = e; if (route === 'home') installHint(); });
function renderHome() {
  route = 'home';
  const t = ay(last.s, last.a);
  $('#view').innerHTML = `
  <header class="hdr">
    <button class="ib" data-go="downloads" aria-label="التنزيلات">${ic('download')}</button>
    <h1 class="title q">القرآن الكريم</h1>
    <button class="ib" data-act="jump" aria-label="انتقال إلى صفحة"><b>#</b></button>
    <button class="ib" data-go="settings" aria-label="الإعدادات">${ic('settings')}</button>
  </header>
  <section class="hero">
    <div class="hero-k">متابعة القراءة</div>
    <div class="hero-s q">${sname(last.s)}</div>
    <div class="hero-m">الجزء ${AR(t[1])} • الصفحة ${AR(last.page)} • ${rec(P.reciter).ar}</div>
    <button class="btn light" data-go="read/${last.page}">${ic('book')} افتح المصحف</button>
  </section>
  <div class="quick">
    <button class="qc" data-go="prayer">${ic('clock')}<div><b>مواقيت الصلاة</b><small>${Prayer.homeLine()}</small></div></button>
    <button class="qc" data-go="qibla">${ic('compass')}<div><b>القبلة</b><small>البوصلة</small></div></button>
  </div>
  <button class="qc wide" data-go="studio">${ic('movie')}<div><b>استوديو الفيديو</b><small>اصنع فيديو تلاوة بخلفية طبيعية</small></div></button>
  <div id="install"></div>
  <nav class="tabs">${['السور', 'الأجزاء', 'العلامات'].map((x, i) => `<button data-tab="${i}" class="${i === homeTab ? 'on' : ''}">${x}</button>`).join('')}</nav>
  <div id="list"></div>`;
  renderList(); installHint();
}
function renderList() {
  const L = $('#list'); if (!L) return;
  if (homeTab === 0) L.innerHTML = QD.surahs.map(s => `<button class="row" data-go="read/${s.ayahs[0][2]}"><span class="num">${AR(s.n)}</span><span class="rt"><span class="q nm">${s.name}</span><small>${s.en} • ${s.type === 'Meccan' ? 'مكية' : 'مدنية'} • ${AR(s.ayahs.length)} آية</small></span><span class="pg">ص ${AR(s.ayahs[0][2])}</span></button>`).join('');
  else if (homeTab === 1) L.innerHTML = juzStart.slice(1).map((j, i) => `<button class="row" data-go="read/${j.page}"><span class="num">${AR(i + 1)}</span><span class="rt"><b>الجزء ${AR(i + 1)}</b><small><span class="q">${sname(j.s)}</span> — الآية ${AR(j.a)}</small></span><span class="pg">ص ${AR(j.page)}</span></button>`).join('');
  else L.innerHTML = marks.length ? marks.map(k => { const [s, a] = k.split(':').map(Number); const t = ay(s, a); return `<button class="row" data-go="read/${t[2]}"><span class="num">${ic('bm')}</span><span class="rt"><span class="q nm">${sname(s)} — ${AR(a)}</span><small class="q">${esc(t[0].split(' ').slice(0, 8).join(' '))}…</small></span><span class="pg">ص ${AR(t[2])}</span></button>`; }).join('')
    : `<div class="empty">لا توجد علامات بعد.<br>اضغط على آية في المصحف ثم زر العلامة.</div>`;
}
function installHint() {
  const el = $('#install'); if (!el) return;
  const standalone = matchMedia('(display-mode: standalone)').matches || navigator.standalone;
  if (standalone || load('hideInstall', false)) { el.innerHTML = ''; return; }
  const ios = /iphone|ipad|ipod/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (ios) el.innerHTML = `<div class="tip">${ic('share')}<span>لتثبيت التطبيق على الآيفون: افتح الموقع في سفاري، اضغط زر المشاركة ثم «إضافة إلى الشاشة الرئيسية».</span><button data-act="hideInstall" aria-label="إخفاء">${ic('close')}</button></div>`;
  else if (deferredPrompt) el.innerHTML = `<div class="tip">${ic('download')}<span>ثبّت التطبيق على جهازك</span><button class="btn sm" data-act="install">تثبيت</button></div>`;
}

/* audio */
const AU = { el: new Audio(), cur: null, playing: false, loading: false, rep: 0, url: null, unlocked: false, tok: 0 };
AU.el.preload = 'auto';
const SILENT = 'data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=';
function unlockAudio() { if (AU.unlocked) return; AU.unlocked = true; try { AU.el.src = SILENT; AU.el.play().catch(() => {}); } catch {} }
async function audioBlob(r, s, a) {
  const url = audioUrl(r, s, a), c = await caches.open(AC).catch(() => null);
  let res = await c?.match(url).catch(() => null);
  if (!res) {
    try { res = await fetch(url); } catch { throw new Error('net'); }
    if (!res.ok) throw new Error(res.status === 404 ? 'missing' : 'net');
    await c?.put(url, res.clone()).catch(() => {});
  }
  return new Blob([await res.arrayBuffer()], { type: 'audio/mpeg' });
}
async function ensureCached(r, s, a) {
  const url = audioUrl(r, s, a), c = await caches.open(AC);
  if (await c.match(url)) return;
  const res = await fetch(url); if (!res.ok) throw new Error(res.status === 404 ? 'missing' : 'net');
  await c.put(url, res);
}
const audioErr = e => e.message === 'missing' ? 'تلاوة هذه الآية غير متوفرة لهذا القارئ' : 'تعذر تحميل التلاوة. تحقق من الاتصال بالإنترنت';
function nextAyah({ s, a }) { if (a < QD.surahs[s - 1].ayahs.length) return { s, a: a + 1 }; return s < 114 ? { s: s + 1, a: 1 } : null; }
function prevAyah({ s, a }) { if (a > 1) return { s, a: a - 1 }; return s > 1 ? { s: s - 1, a: QD.surahs[s - 2].ayahs.length } : null; }
function playAyah(s, a) { AU.cur = { s, a }; AU.rep = 0; startCur(); }
async function startCur() {
  const tok = ++AU.tok, { s, a } = AU.cur;
  AU.loading = true; renderBar(); markPlaying(true);
  try {
    const blob = await audioBlob(P.reciter, s, a).catch(e => { if (e.message === 'missing') throw e; return null; });
    if (tok !== AU.tok) return;
    if (AU.url) URL.revokeObjectURL(AU.url);
    AU.url = blob ? URL.createObjectURL(blob) : null;
    try { AU.el.src = AU.url || audioUrl(P.reciter, s, a); AU.el.playbackRate = P.speed; await AU.el.play(); }
    catch (e) {
      if (!AU.url || e.name === 'NotAllowedError' || tok !== AU.tok) throw e;
      AU.url = null; AU.el.src = audioUrl(P.reciter, s, a); await AU.el.play();
    }
    AU.el.playbackRate = P.speed;
    AU.loading = false; mediaMeta();
    const n = nextAyah(AU.cur); if (n) ensureCached(P.reciter, n.s, n.a).catch(() => {});
  } catch (e) {
    if (tok !== AU.tok) return;
    AU.loading = false; AU.playing = false;
    toast(e.name === 'NotAllowedError' ? 'اضغط زر التشغيل للمتابعة' : audioErr(e), 'إعادة المحاولة', () => { unlockAudio(); startCur(); });
  }
  renderBar();
}
AU.el.addEventListener('play', () => { if (AU.el.src === SILENT) return; AU.playing = true; renderBar(); setMS('playing'); });
AU.el.addEventListener('pause', () => { AU.playing = false; renderBar(); setMS('paused'); });
AU.el.addEventListener('ended', () => {
  if (!AU.cur || AU.el.src === SILENT) return;
  if (++AU.rep < P.repeat) { AU.el.currentTime = 0; AU.el.play(); return; }
  const n = nextAyah(AU.cur);
  if (!P.continuous || !n) { stopAudio(); return; }
  AU.cur = n; AU.rep = 0; startCur();
});
function stopAudio() {
  AU.tok++; AU.el.pause(); AU.cur = null; AU.playing = false; AU.loading = false;
  renderBar(); markPlaying(false); setMS('none');
}
function togglePlay() {
  unlockAudio();
  if (AU.playing) AU.el.pause();
  else if (AU.cur && AU.el.src && AU.el.src !== SILENT && !AU.el.ended) AU.el.play().catch(() => startCur());
  else if (AU.cur) startCur();
  else { const [s, a] = (selKey || `${pages[curPage][0][0]}:${pages[curPage][0][1]}`).split(':').map(Number); playAyah(s, a); }
}
function step(d) { const base = AU.cur || (selKey && { s: +selKey.split(':')[0], a: +selKey.split(':')[1] }); if (!base) return; const n = d > 0 ? nextAyah(base) : prevAyah(base); if (n) { unlockAudio(); playAyah(n.s, n.a); } }
function setMS(st) { if ('mediaSession' in navigator) { navigator.mediaSession.playbackState = st; if (st === 'none') navigator.mediaSession.metadata = null; } }
function mediaMeta() {
  if (!('mediaSession' in navigator) || !AU.cur) return;
  navigator.mediaSession.metadata = new MediaMetadata({ title: `${sname(AU.cur.s).replace(/[\u064B-\u0652\u0670\u06DF-\u06ED]/g, '')} — الآية ${AR(AU.cur.a)}`, artist: rec(P.reciter).ar, album: 'القرآن الكريم', artwork: [{ src: 'icons/icon-512.png', sizes: '512x512', type: 'image/png' }] });
}
if ('mediaSession' in navigator) {
  const ms = navigator.mediaSession;
  ms.setActionHandler('play', () => togglePlay()); ms.setActionHandler('pause', () => AU.el.pause());
  ms.setActionHandler('nexttrack', () => step(1)); ms.setActionHandler('previoustrack', () => step(-1));
  try { ms.setActionHandler('stop', () => stopAudio()); } catch {}
}

/* reader */
let curPage = 1, selKey = null, wake = null;
async function acquireWake() { if (!P.wake || !('wakeLock' in navigator) || route !== 'read') return; try { wake = await navigator.wakeLock.request('screen'); } catch {} }
function releaseWake() { wake?.release?.().catch(() => {}); wake = null; }
document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible' && route === 'read') acquireWake(); });
function pageHtml(p) {
  let out = '', para = '';
  for (const [s, a] of pages[p]) {
    if (a === 1) {
      if (para) { out += `<p>${para}</p>`; para = ''; }
      out += `<div class="sh"><span>${sname(s)}</span></div>`;
      if (s !== 1 && s !== 9) out += `<div class="bas">${QD.basmala}</div>`;
    }
    para += `<span class="ay" data-k="${s}:${a}">${ay(s, a)[0]}<span class="mk">&nbsp;\u06DD${AR(a)}</span></span> `;
  }
  return out + (para ? `<p>${para}</p>` : '');
}
function renderReader(p) {
  p = Math.min(604, Math.max(1, p | 0)); curPage = p; route = 'read';
  const [fs, fa] = pages[p][0], first = ay(fs, fa);
  last = { page: p, s: fs, a: fa }; save('last', last);
  $('#view').innerHTML = `
  ${header(`<span class="q">${sname(fs)}</span>`, `الجزء ${AR(first[1])} • الصفحة ${AR(p)}`, `<button class="ib" data-go="settings" aria-label="الإعدادات">${ic('settings')}</button>`)}
  <div class="page-wrap"><article class="page q" id="page">${pageHtml(p)}</article>
  <div class="pager"><button class="ib" data-act="turn" data-d="-1" aria-label="الصفحة السابقة" ${p === 1 ? 'disabled' : ''}>${ic('chr')}</button><span>${AR(p)} / ${AR(604)}</span><button class="ib" data-act="turn" data-d="1" aria-label="الصفحة التالية" ${p === 604 ? 'disabled' : ''}>${ic('chl')}</button></div></div>
  <div id="bar" class="bar"></div>`;
  const pw = $('.page-wrap'); let sx = 0, sy = 0;
  pw.addEventListener('touchstart', e => { sx = e.touches[0].clientX; sy = e.touches[0].clientY; }, { passive: true });
  pw.addEventListener('touchend', e => { const dx = e.changedTouches[0].clientX - sx, dy = e.changedTouches[0].clientY - sy; if (Math.abs(dx) > 70 && Math.abs(dx) > Math.abs(dy) * 1.5) turn(dx > 0 ? 1 : -1); });
  renderBar(); markPlaying(false); acquireWake();
}
function turn(d) { const p = curPage + d; if (p < 1 || p > 604) return; history.replaceState(null, '', '#read/' + p); renderReader(p); }
function markPlaying(scroll) {
  if (route !== 'read') return;
  $$('.ay.on').forEach(e => e.classList.remove('on'));
  $$('.ay.sel').forEach(e => e.classList.remove('sel'));
  if (selKey && !AU.cur) $(`.ay[data-k="${selKey}"]`)?.classList.add('sel');
  if (!AU.cur) return;
  const k = `${AU.cur.s}:${AU.cur.a}`, pg = ay(AU.cur.s, AU.cur.a)[2];
  if (pg !== curPage) { if (P.follow && scroll) { history.replaceState(null, '', '#read/' + pg); renderReader(pg); } else return; }
  const el = $(`.ay[data-k="${k}"]`); if (!el) return;
  el.classList.add('on');
  if (scroll && P.follow) el.scrollIntoView({ block: 'center', behavior: 'smooth' });
}
function renderBar() {
  const b = $('#bar'); if (!b) return;
  const k = AU.cur ? `${AU.cur.s}:${AU.cur.a}` : selKey;
  if (!k) { b.innerHTML = `<div class="hint">اضغط على أي آية للاستماع بصوت ${rec(P.reciter).ar}</div>`; return; }
  const [s, a] = k.split(':').map(Number), on = AU.playing || AU.loading;
  b.innerHTML = `<div class="bi"><b class="q">${sname(s)}</b><small>الآية ${AR(a)} • ${rec(P.reciter).ar}${AU.loading ? ' • جارٍ التحميل…' : ''}</small></div>
  <div class="bc">
    <button class="ib" data-act="bm" data-k="${k}" aria-label="علامة">${ic(marks.includes(k) ? 'bm' : 'bmo')}</button>
    <button class="ib" data-act="speed" aria-label="السرعة"><b style="font-size:14px">${AR(P.speed)}×</b></button>
    <button class="ib" data-act="prevA" aria-label="الآية السابقة">${ic('prev', 'mir')}</button>
    <button class="fab" data-act="toggle" aria-label="${on ? 'إيقاف مؤقت' : 'تشغيل'}">${ic(on ? 'pause' : 'play')}</button>
    <button class="ib" data-act="nextA" aria-label="الآية التالية">${ic('next', 'mir')}</button>
    <button class="ib ${P.repeat > 1 ? 'on' : ''}" data-act="repeat" aria-label="التكرار">${ic('repeat')}${P.repeat > 1 ? `<sup>${AR(P.repeat)}</sup>` : ''}</button>
    <button class="ib" data-act="stop" aria-label="إيقاف">${ic('stop')}</button>
  </div>`;
}

/* settings */
function renderSettings() {
  route = 'settings';
  const y = window.scrollY;
  $('#view').innerHTML = `${header('الإعدادات')}
  <div class="pad">
    <section class="card"><h3>القارئ</h3>${seg('reciter', RECITERS.map(r => [r.id, r.ar]), 'col')}</section>
    <section class="card"><h3>المظهر</h3>${seg('theme', [['system', 'تلقائي'], ['light', 'فاتح'], ['dark', 'داكن']])}
      <h3>لون الصفحة</h3>${seg('pageStyle', PAGE_STYLES.map((n, i) => [i, `<i class="sw4" style="background:${(isDark() ? PAGE_D : PAGE_L)[i][0]}"></i>${n}`]))}
      <h3>حجم الخط</h3><input type="range" data-rng="font" min="20" max="48" step="1" value="${P.font}">
      <h3>تباعد الأسطر</h3><input type="range" data-rng="line" min="1.5" max="2.6" step="0.1" value="${P.line}">
      <div class="sample q">${QD.basmala}</div></section>
    <section class="card"><h3>التلاوة</h3>
      <div class="rowx"><span>سرعة التلاوة</span></div>${seg('speed', [[0.75, '٠٫٧٥×'], [1, '١×'], [1.25, '١٫٢٥×'], [1.5, '١٫٥×'], [2, '٢×']])}
      <div class="rowx"><span>تكرار كل آية</span></div>${seg('repeat', [[1, 'بدون'], [2, '٢'], [3, '٣'], [5, '٥'], [10, '١٠']])}
      <div class="rowx"><span>تشغيل متواصل<small>الانتقال تلقائياً إلى الآية التالية</small></span>${sw('continuous')}</div>
      <div class="rowx"><span>متابعة الآية المقروءة<small>تقليب الصفحة تلقائياً مع التلاوة</small></span>${sw('follow')}</div>
      <div class="rowx"><span>متابعة التلاوة بعد الخروج من المصحف</span>${sw('keepPlaying')}</div>
      <div class="rowx"><span>إبقاء الشاشة مضاءة أثناء القراءة</span>${sw('wake')}</div></section>
    <section class="card"><h3>حول</h3><small>نص القرآن: <a href="https://tanzil.net" target="_blank" rel="noopener">Tanzil Project</a> (الرسم العثماني، CC BY 3.0، دون أي تعديل). التلاوات: <a href="https://everyayah.com" target="_blank" rel="noopener">EveryAyah.com</a>. مواقيت الصلاة: مكتبة Adhan (MIT).</small></section>
  </div>`;
  window.scrollTo(0, y);
}
function onPref(k) {
  if (k === 'speed') AU.el.playbackRate = P.speed;
  if (k === 'reciter' && AU.cur) startCur();
  if (['method', 'hanafi', 'notify'].includes(k)) Prayer.refresh(k);
}

/* downloads */
const DL = { q: [], cur: null, done: 0, total: 0, cancel: false };
const dlKey = () => 'dl:' + P.reciter;
const dlDone = () => load(dlKey(), []);
function renderDownloads() {
  route = 'downloads';
  const done = dlDone();
  $('#view').innerHTML = `${header('التنزيلات', rec(P.reciter).ar)}
  <div class="pad"><div class="card"><p class="note">نزّل السور للاستماع بدون إنترنت. يمكن تغيير القارئ من الإعدادات. كل آية تستمع إليها تحفظ تلقائياً أيضاً.</p>
    <div class="btns"><button class="btn" data-act="dlAll">${ic('download')} تنزيل القرآن كاملاً</button>${DL.cur || DL.q.length ? `<button class="btn ghost" data-act="dlCancel">إلغاء</button>` : ''}</div>
    ${DL.cur ? `<small>جارٍ تنزيل <span class="q">${sname(DL.cur)}</span> ${AR(DL.done)}/${AR(DL.total)}${DL.q.length ? ` • ${AR(DL.q.length)} في الانتظار` : ''}</small><div class="prog"><i style="width:${DL.total ? DL.done / DL.total * 100 : 0}%"></i></div>` : ''}</div>
  <div>${QD.surahs.map(s => `<div class="dlr"><span class="num">${AR(s.n)}</span><span class="rt"><span class="q nm">${s.name}</span><small>${AR(s.ayahs.length)} آية</small></span>${done.includes(s.n) ? `${ic('check')}<button class="ib" data-act="dlDel" data-n="${s.n}" aria-label="حذف">${ic('del')}</button>` : DL.cur === s.n || DL.q.includes(s.n) ? `<small>${DL.cur === s.n ? AR(Math.round(DL.done / Math.max(1, DL.total) * 100)) + '٪' : 'في الانتظار'}</small>` : `<button class="ib" data-act="dl" data-n="${s.n}" aria-label="تنزيل">${ic('download')}</button>`}</div>`).join('')}</div></div>`;
}
function enqueue(ns) { navigator.storage?.persist?.(); for (const n of ns) if (!DL.q.includes(n) && DL.cur !== n && !dlDone().includes(n)) DL.q.push(n); if (!DL.cur) runDL(); else if (route === 'downloads') renderDownloads(); }
async function runDL() {
  DL.cancel = false;
  while (DL.q.length && !DL.cancel) {
    const n = DL.cur = DL.q.shift(), r = P.reciter, list = QD.surahs[n - 1].ayahs.map((_, i) => i + 1);
    DL.done = 0; DL.total = list.length; let failed = null, i = 0;
    if (route === 'downloads') renderDownloads();
    await Promise.all([0, 1, 2, 3].map(async () => {
      while (i < list.length && !DL.cancel && !failed) {
        const a = list[i++];
        try { await ensureCached(r, n, a); DL.done++; } catch (e) { failed = e; }
        if (route === 'downloads') { const bar = $('.prog i'); if (bar) bar.style.width = DL.done / DL.total * 100 + '%'; }
      }
    }));
    if (failed) { toast(audioErr(failed), 'إعادة المحاولة', () => enqueue([n])); DL.q = []; }
    else if (!DL.cancel) { const k = 'dl:' + r, d = load(k, []); d.push(n); save(k, d); }
    DL.cur = null; if (route === 'downloads') renderDownloads();
  }
  DL.cur = null; if (route === 'downloads') renderDownloads();
}
async function deleteSurah(n) {
  const c = await caches.open(AC), s = QD.surahs[n - 1];
  await Promise.all(s.ayahs.map((_, i) => c.delete(audioUrl(P.reciter, n, i + 1))));
  save(dlKey(), dlDone().filter(x => x !== n)); renderDownloads();
}

/* events */
const ACT = {
  back, jump() {
    const m = modal(`<h3>انتقال إلى صفحة</h3><input type="number" inputmode="numeric" min="1" max="604" placeholder="١ – ٦٠٤" id="jp"><div class="acts"><button class="btn ghost" data-close>إلغاء</button><button class="btn" id="jgo">انتقال</button></div>`);
    const i = $('#jp', m); i.focus();
    const ok = () => { const p = parseInt(String(i.value).replace(/[٠-٩]/g, d => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)), 10); if (p >= 1 && p <= 604) { m.remove(); go('read/' + p); } else toast('أدخل رقم صفحة من ١ إلى ٦٠٤'); };
    $('#jgo', m).onclick = ok; i.onkeydown = e => { if (e.key === 'Enter') ok(); };
  },
  turn(el) { turn(+el.dataset.d); }, toggle: togglePlay, stop: stopAudio,
  prevA: () => step(-1), nextA: () => step(1),
  speed() { const L = [0.75, 1, 1.25, 1.5, 2]; setP('speed', L[(L.indexOf(P.speed) + 1) % L.length]); renderBar(); },
  repeat() { const L = [1, 2, 3, 5, 10]; setP('repeat', L[(L.indexOf(P.repeat) + 1) % L.length]); renderBar(); },
  bm(el) { const k = el.dataset.k; marks = marks.includes(k) ? marks.filter(x => x !== k) : [...marks, k]; save('marks', marks); toast(marks.includes(k) ? 'تمت إضافة العلامة' : 'تمت إزالة العلامة'); renderBar(); },
  hideInstall() { save('hideInstall', true); installHint(); },
  async install() { if (!deferredPrompt) return; deferredPrompt.prompt(); await deferredPrompt.userChoice; deferredPrompt = null; installHint(); },
  dl(el) { enqueue([+el.dataset.n]); }, dlDel(el) { deleteSurah(+el.dataset.n); },
  dlAll() { if (confirm('تنزيل القرآن كاملاً يحتاج مساحة كبيرة (قرابة ١ جيجابايت). هل تريد المتابعة؟')) enqueue(QD.surahs.map(s => s.n)); },
  dlCancel() { DL.cancel = true; DL.q = []; renderDownloads(); },
};
document.addEventListener('click', e => {
  const t = e.target;
  const ayEl = t.closest('.ay');
  if (ayEl && route === 'read') { unlockAudio(); const k = ayEl.dataset.k; selKey = k; const [s, a] = k.split(':').map(Number); playAyah(s, a); return; }
  const g = t.closest('[data-go]'); if (g) { go(g.dataset.go); return; }
  const tab = t.closest('[data-tab]'); if (tab) { homeTab = +tab.dataset.tab; $$('.tabs button').forEach(b => b.classList.toggle('on', b === tab)); renderList(); return; }
  const st = t.closest('[data-set]'); if (st) { setP(st.dataset.set, JSON.parse(st.dataset.v)); if (route === 'settings') renderSettings(); return; }
  const a = t.closest('[data-act]'); if (a) { const f = ACT[a.dataset.act] || Prayer.act?.[a.dataset.act] || Qibla.act?.[a.dataset.act] || Studio.act?.[a.dataset.act]; if (f) f(a, e); }
});
document.addEventListener('change', e => {
  const t = e.target;
  if (t.dataset.sw) setP(t.dataset.sw, t.checked);
  else if (t.dataset.sel) setP(t.dataset.sel, t.value);
});
document.addEventListener('input', e => { const t = e.target; if (t.dataset.rng) setP(t.dataset.rng, +t.value); });
document.addEventListener('keydown', e => { if (route === 'read' && !e.target.closest('input')) { if (e.key === 'ArrowLeft') turn(1); if (e.key === 'ArrowRight') turn(-1); if (e.key === ' ') { e.preventDefault(); togglePlay(); } } });

async function init() {
  applyTheme();
  try { await loadData(); } catch { $('#view').innerHTML = `<div class="empty">تعذر تحميل بيانات القرآن. تحقق من الاتصال ثم <a href="">أعد المحاولة</a>.</div>`; return; }
  render(); Prayer.init();
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
}
document.addEventListener('DOMContentLoaded', init);
