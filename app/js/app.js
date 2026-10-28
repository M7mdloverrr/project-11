'use strict';
const ARQ = v => String(v).replace(/\d/g, c => '٠١٢٣٤٥٦٧٨٩'[c]).replace('.', '٫');
const AR = v => DE_UI ? String(v).replace('.', ',') : ARQ(v);
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const load = (k, d) => { try { const v = JSON.parse(localStorage.getItem(k)); return v ?? d; } catch { return d; } };
const save = (k, v) => localStorage.setItem(k, JSON.stringify(v));
const DE_UI = load('prefs', {}).lang === 'de';
const TR = (ar, de) => DE_UI ? de : ar;
const SDE = ["Die Eröffnung", "Die Kuh", "Die Sippe Imrans", "Die Frauen", "Der Tisch", "Das Vieh", "Die Höhen", "Die Beute", "Die Reue", "Yunus", "Hud", "Yusuf", "Der Donner", "Ibrahim", "Al-Hidschr", "Die Bienen", "Die Nachtreise", "Die Höhle", "Maryam", "Ta-Ha", "Die Propheten", "Die Pilgerfahrt", "Die Gläubigen", "Das Licht", "Die Unterscheidung", "Die Dichter", "Die Ameisen", "Die Geschichte", "Die Spinne", "Die Römer", "Luqman", "Die Niederwerfung", "Die Gruppierungen", "Saba", "Der Erschaffer", "Ya-Sin", "Die sich Reihenden", "Sad", "Die Scharen", "Der Vergebende", "Ausführlich dargelegt", "Die Beratung", "Der Goldprunk", "Der Rauch", "Die Kniende", "Die Sanddünen", "Muhammad", "Der Sieg", "Die Gemächer", "Qaf", "Die Aufwirbelnden", "Der Berg", "Der Stern", "Der Mond", "Der Allerbarmer", "Das eintreffende Ereignis", "Das Eisen", "Der Streit", "Die Versammlung", "Die Geprüfte", "Die Reihe", "Der Freitag", "Die Heuchler", "Die gegenseitige Übervorteilung", "Die Scheidung", "Das Verbieten", "Die Herrschaft", "Das Schreibrohr", "Die fällig Werdende", "Die Himmelsleiter", "Nuh", "Die Dschinn", "Der Eingehüllte", "Der Zugedeckte", "Die Auferstehung", "Der Mensch", "Die Entsandten", "Die Kunde", "Die Entreißenden", "Er runzelte die Stirn", "Das Einrollen", "Das Zerbrechen", "Die das Maß Kürzenden", "Das Zerreißen", "Die Türme", "Der Pochende", "Der Höchste", "Die Überdeckende", "Die Morgendämmerung", "Die Ortschaft", "Die Sonne", "Die Nacht", "Die Morgenhelle", "Das Auftun", "Die Feige", "Das Anhaftende", "Die Bestimmung", "Der klare Beweis", "Das Beben", "Die Rennenden", "Das Verhängnis", "Die Vermehrung", "Das Zeitalter", "Der Stichler", "Der Elefant", "Die Quraisch", "Die Hilfeleistung", "Die Fülle", "Die Ungläubigen", "Die Hilfe", "Die Palmfasern", "Die Aufrichtigkeit", "Das Frühlicht", "Die Menschen"];

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
  full: 'M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z',
  fullx: 'M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z',
  upload: 'M18 15v3H6v-3H4v3c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2v-3h-2zM7 9l1.41 1.41L11 7.83V16h2V7.83l2.59 2.58L17 9l-5-5-5 5z',
};
const ic = (n, cls = '') => `<svg class="ic ${cls}" viewBox="0 0 24 24" aria-hidden="true"><path d="${ICON[n]}"/></svg>`;

const MP3Q = 'https://cdn.mp3quran.net/audio/';
const RECITERS = [
  { id: 'maher', ar: 'ماهر المعيقلي', en: 'Maher Al-Muaiqly', f: 'MaherAlMuaiqly128kbps' },
  { id: 'alafasy', ar: 'مشاري العفاسي', en: 'Mishary Alafasy', f: 'Alafasy_128kbps' },
  { id: 'sudais', ar: 'عبد الرحمن السديس', en: 'Abdul Rahman Al-Sudais', f: 'Abdurrahmaan_As-Sudais_192kbps' },
  { id: 'basit', ar: 'عبد الباسط عبد الصمد', en: 'Abdul Basit Abdul Samad', f: 'Abdul_Basit_Murattal_192kbps' },
  { id: 'minshawi', ar: 'محمد صديق المنشاوي', en: 'Muhammad Siddiq Al-Minshawi', f: 'Minshawy_Murattal_128kbps' },
  { id: 'husary', ar: 'محمود خليل الحصري', en: 'Mahmoud Khalil Al-Husary', f: 'Husary_128kbps' },
  { id: 'husary_mj', ar: 'الحصري (مجوّد)', en: 'Al-Husary (Mujawwad)', f: 'Husary_Mujawwad_64kbps' },
  { id: 'minshawi_mj', ar: 'المنشاوي (مجوّد)', en: 'Al-Minshawi (Mujawwad)', f: 'Minshawy_Mujawwad_192kbps' },
  { id: 'ajamy', ar: 'أحمد العجمي', en: 'Ahmed Al-Ajamy', f: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net' },
  { id: 'shuraim', ar: 'سعود الشريم', en: 'Saud Al-Shuraim', f: 'Saood_ash-Shuraym_128kbps' },
  { id: 'ghamdi', ar: 'سعد الغامدي', en: 'Saad Al-Ghamdi', f: 'Ghamadi_40kbps' },
  { id: 'dossari', ar: 'ياسر الدوسري', en: 'Yasser Al-Dossari', f: 'Yasser_Ad-Dussary_128kbps' },
  { id: 'hudhaify', ar: 'علي الحذيفي', en: 'Ali Al-Hudhaify', f: 'Hudhaify_128kbps' },
  { id: 'shatri', ar: 'أبو بكر الشاطري', en: 'Abu Bakr Al-Shatri', f: 'Abu_Bakr_Ash-Shaatree_128kbps' },
  { id: 'ayyoub', ar: 'محمد أيوب', en: 'Muhammad Ayyoub', f: 'Muhammad_Ayyoub_128kbps' },
  { id: 'qatami', ar: 'ناصر القطامي', en: 'Nasser Al-Qatami', f: 'Nasser_Alqatami_128kbps' },
  { id: 'jaber', ar: 'علي جابر', en: 'Ali Jaber', f: 'Ali_Jaber_64kbps' },
  { id: 'abbad', ar: 'فارس عباد', en: 'Fares Abbad', f: 'Fares_Abbad_64kbps' },
  { id: 'basfar', ar: 'عبد الله بصفر', en: 'Abdullah Basfar', f: 'Abdullah_Basfar_192kbps' },
  { id: 'budair', ar: 'صلاح البدير', en: 'Salah Al-Budair', f: 'Salah_Al_Budair_128kbps' },
  { id: 'rifai', ar: 'هاني الرفاعي', en: 'Hani Ar-Rifai', f: 'Hani_Rifai_192kbps' },
  { id: 'sufi_hafs', ar: 'عبد الرشيد صوفي (حفص عن عاصم)', en: 'Abdul Rashid Sufi (Hafs)', sb: MP3Q + 'abdulrasheed-sufi/r3/', tm: 'sufi' },
  { id: 'mousa_hafs', ar: 'عبدالله الموسى', en: 'Abdullah Al-Mousa', sb: MP3Q + 'abdullah-mousa/r1/', tm: 'mousa' },
];
const rec = id => RECITERS.find(r => r.id === id) || RECITERS[0];
const pad3 = n => String(n).padStart(3, '0');
const audioUrl = (r, s, a) => { const R = rec(r); return R.sb ? `${R.sb}${pad3(s)}.mp3?ayah=${a}` : `https://everyayah.com/data/${R.f}/${pad3(s)}${pad3(a)}.mp3`; };

/* whole-surah reciters (mp3quran.net): each ayah is cut out of the CBR surah file by byte range using bundled ms timings */
const TIM = {}, LAY = {};
const KBPS = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0], SRATE = [44100, 48000, 32000];
function timing(tm) {
  return TIM[tm] ||= fetch(`assets/timing/${tm}.json`).then(r => { if (!r.ok) throw new Error('net'); return r.json(); }).then(j => j.s)
    .catch(() => { delete TIM[tm]; throw new Error('net'); });
}
async function getRange(url, a, b) {
  let r; try { r = await fetch(url, { headers: { Range: `bytes=${a}-${b}` } }); } catch { throw new Error('net'); }
  if (!r.ok) throw new Error(r.status === 404 ? 'missing' : 'net');
  const d = new Uint8Array(await r.arrayBuffer());
  return r.status === 206 ? d : d.subarray(a, b + 1);
}
function frameLen(d, i) {
  if (i + 4 > d.length || d[i] !== 0xFF || (d[i + 1] & 0xFE) !== 0xFA) return 0;
  const kb = KBPS[d[i + 2] >> 4], sr = SRATE[(d[i + 2] >> 2) & 3];
  return kb && sr ? Math.floor(144000 * kb / sr) + ((d[i + 2] >> 1) & 1) : 0;
}
function syncAt(d) { for (let i = 0; i + 4 < d.length; i++) { const n = frameLen(d, i); if (n && frameLen(d, i + n)) return i; } return -1; }
async function layout(R, s) {
  const k = R.id + ':' + s; if (LAY[k]) return LAY[k];
  const url = `${R.sb}${pad3(s)}.mp3`, h = await getRange(url, 0, 9);
  const id3 = h[0] === 0x49 && h[1] === 0x44 && h[2] === 0x33 ? 10 + ((h[6] & 127) << 21 | (h[7] & 127) << 14 | (h[8] & 127) << 7 | (h[9] & 127)) : 0;
  const d = await getRange(url, id3, id3 + 8191), i = syncAt(d); if (i < 0) throw new Error('net');
  return LAY[k] = { url, first: id3 + i, bpm: KBPS[d[i + 2] >> 4] / 8 };
}
async function clipBytes(R, s, a) {
  const t = (await timing(R.tm))[s - 1], st = t?.[(a - 1) * 2], en = t?.[(a - 1) * 2 + 1];
  if (st == null || en == null) throw new Error('missing');
  const L = await layout(R, s), d = await getRange(L.url, L.first + Math.floor(st * L.bpm), L.first + Math.ceil(en * L.bpm) - 1);
  const i = syncAt(d); if (i < 0) throw new Error('net');
  return d.subarray(i);
}
async function fetchAudio(r, s, a) {
  const R = rec(r);
  if (R.sb) return new Response(await clipBytes(R, s, a), { headers: { 'Content-Type': 'audio/mpeg' } });
  let res; try { res = await fetch(audioUrl(r, s, a)); } catch { throw new Error('net'); }
  if (!res.ok) throw new Error(res.status === 404 ? 'missing' : 'net');
  return res;
}
const AC = 'quran-audio-v1';

const DEF = { theme: 'system', pageStyle: 0, font: 28, line: 1.9, script: 0, qfont: 0, tafsir: 0, tafsirUnder: false, pageFlip: false, bgAlpha: 0.3, lang: 'ar', reciter: 'maher', speed: 1, repeat: 1, continuous: true, follow: true, keepPlaying: false, wake: true, de: 0, method: 'MuslimWorldLeague', hanafi: false, notify: false };
const P = Object.assign({}, DEF, load('prefs', {}));
let last = load('last', { page: 1, s: 1, a: 1 });
let marks = load('marks', []);
function setP(k, v) { P[k] = v; save('prefs', P); applyTheme(); onPref(k); }
let DE = null, deLoading = null;
function loadDE() {
  if (DE || deLoading) return deLoading;
  deLoading = fetch('assets/de.json').then(r => { if (!r.ok) throw 0; return r.json(); })
    .then(j => { DE = j.s; if (route === 'read') renderReader(curPage); })
    .catch(() => { deLoading = null; if (typeof toast === 'function') toast(TR('تعذر تحميل الترجمة. تحقق من الاتصال بالإنترنت', 'Übersetzung konnte nicht geladen werden. Bitte Internetverbindung prüfen.')); });
  return deLoading;
}
const deText = (s, a) => (DE && DE[s - 1] && DE[s - 1][a - 1]) || '';

/* Mushaf script + font (KFGQPC Hafs default, like the Android app) */
const SCRIPTS = [[TR('الرسم العثماني • مجمع الملك فهد', 'Uthmani • King-Fahd-Komplex'), 'qpc', 'Hafs'], [TR('الرسم العثماني • تنزيل', 'Uthmani • Tanzil'), null, null], [TR('الرسم الإملائي', 'Imlaei (einfache Schreibweise)'), 'imlaei', null], [TR('الرسم الهندي/الباكستاني', 'IndoPak'), 'indopak', 'IndoPak']];
const QFONTS = [['QuranFont', TR('أميري قرآن', 'Amiri Quran')], ['Amiri', TR('أميري', 'Amiri')], ['Scheherazade', TR('شهرزاد', 'Scheherazade')], ['NotoNaskh', TR('نسخ', 'Naskh')]];
let SC = null; const scCache = {};
async function loadScript(i) {
  const f = SCRIPTS[i]?.[1];
  if (!f) { SC = null; return; }
  SC = await (scCache[i] ||= fetch(`assets/script/${f}.json`).then(r => { if (!r.ok) throw 0; return r.json(); }).then(j => j.s)
    .catch(e => { delete scCache[i]; throw e; }));
}
const atext = (s, a) => SC?.[s - 1]?.[a - 1] || ay(s, a)[0];
const basm = () => SC?.[0]?.[0] || QD.basmala;
const ayahFont = () => SCRIPTS[P.script]?.[2] || QFONTS[P.qfont]?.[0] || 'QuranFont';
const mark = a => (P.script === 0 ? '' : '\u06DD') + ARQ(a);

/* tafsir: Al-Muyassar bundled (offline), the rest online (alquran.cloud / quran.com), cached */
const TAFSIRS = [[TR('التفسير الميسر', 'Tafsir al-Muyassar')], [TR('تفسير الجلالين', 'Tafsir al-Dschalalain'), 0, 'ar.jalalayn'], [TR('تفسير السعدي', 'Tafsir as-Saadi'), 91], [TR('تفسير ابن كثير', 'Tafsir Ibn Kathir'), 14], [TR('تفسير الطبري', 'Tafsir at-Tabari'), 15], [TR('تفسير القرطبي', 'Tafsir al-Qurtubi'), 90], [TR('تفسير البغوي', 'Tafsir al-Baghawi'), 94], [TR('التفسير الوسيط (طنطاوي)', 'At-Tafsir al-Wasit (Tantawi)'), 93]];
const TC = 'quran-tafsir-v1';
let MUY = null;
function htmlText(h) {
  const d = new DOMParser().parseFromString(`<div>${String(h).replace(/<br\s*\/?>/gi, '\n').replace(/<\/(p|h\d|div)>/gi, '\n\n')}</div>`, 'text/html');
  return (d.body.textContent || '').replace(/[ \t]+\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim();
}
async function tafsirText(i, s, a) {
  const t = TAFSIRS[i] || TAFSIRS[0];
  if (!t[1] && !t[2]) {
    const m = await (MUY ||= fetch('assets/muyassar.json').then(r => { if (!r.ok) throw 0; return r.json(); }).then(j => j.s).catch(e => { MUY = null; throw e; }));
    return m[s - 1]?.[a - 1] || '';
  }
  const url = t[2] ? `https://api.alquran.cloud/v1/ayah/${s}:${a}/${t[2]}` : `https://api.quran.com/api/v4/tafsirs/${t[1]}/by_ayah/${s}:${a}`;
  const c = await caches.open(TC).catch(() => null);
  let res = await c?.match(url).catch(() => null);
  if (!res) { res = await fetch(url); if (!res.ok) throw new Error('net'); await c?.put(url, res.clone()).catch(() => {}); }
  const j = await res.json();
  return htmlText((t[2] ? j.data?.text : j.tafsir?.text) || '');
}
function showTafsir(s, a) {
  const m = modal(`<div class="tfh"><h3><span class="q">${sname(s)}</span> • ${TR('الآية', 'Vers')} ${AR(a)}</h3><button class="ib" data-close aria-label="${TR('إغلاق', 'Schließen')}">${ic('close')}</button></div>
  <div class="chips tfc">${TAFSIRS.map((t, i) => `<button data-tf="${i}" class="${P.tafsir === i ? 'on' : ''}">${t[0]}</button>`).join('')}</div>
  <div class="tfb"><div class="tf-ay">${atext(s, a)} <span class="mk">${mark(a)}</span></div><div id="tft"></div></div>`);
  m.classList.add('bottom');
  let tok = 0;
  const fill = async () => {
    const my = ++tok, el = $('#tft', m);
    el.innerHTML = '<div class="spin"></div>';
    try { const txt = await tafsirText(P.tafsir, s, a); if (my === tok) el.textContent = txt || TR('تفسير هذه الآية مذكور مع الآيات المجاورة.', 'Die Erklärung dieses Verses steht bei den benachbarten Versen.'); }
    catch { if (my !== tok) return; el.innerHTML = `<p class="err">${TR('تعذّر تحميل التفسير. تحقق من الاتصال بالإنترنت.', 'Tafsir konnte nicht geladen werden. Bitte Internetverbindung prüfen.')}</p><button class="btn ghost sm" id="tfr">${TR('إعادة المحاولة', 'Erneut versuchen')}</button>`; $('#tfr', m).onclick = fill; }
  };
  m.addEventListener('click', e => { const b = e.target.closest('[data-tf]'); if (!b) return; setP('tafsir', +b.dataset.tf); $$('[data-tf]', m).forEach(x => x.classList.toggle('on', x === b)); fill(); });
  fill();
}
function fillTafsirUnder() {
  for (const el of $$('.tfu')) {
    const [s, a] = el.dataset.tk.split(':').map(Number), i = P.tafsir;
    tafsirText(i, s, a).then(t => { if (P.tafsir === i) { el.textContent = t; el.hidden = !t; } }).catch(() => { el.hidden = true; });
  }
}

/* data */
let QD = null; const pages = []; const juzStart = [];
const ay = (s, a) => QD.surahs[s - 1].ayahs[a - 1];
const sname = s => DE_UI ? SDE[s - 1] : QD.surahs[s - 1].name;
const rname = r => DE_UI ? r.en : r.ar;
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
const PAGE_STYLES = [TR('ورق المصحف', 'Mushaf-Papier'), TR('كريمي', 'Creme'), TR('أخضر هادئ', 'Sanftes Grün'), TR('سادة', 'Schlicht')];
const PAGE_L = [['#FBF3DF', '#1B1B18'], ['#F2E3C2', '#2A1E10'], ['#EAF4EC', '#10201A'], ['#FFFFFF', '#000000']];
const PAGE_D = [['#1E1B14', '#EFE6D2'], ['#2A2116', '#F1E2C4'], ['#0F2A21', '#E8F3EE'], ['#17201D', '#F3F3F0']];
const darkMQ = matchMedia('(prefers-color-scheme: dark)');
const isDark = () => P.theme === 'dark' || (P.theme === 'system' && darkMQ.matches);
function applyTheme() {
  const d = isDark(), root = document.documentElement, [bg, ink] = (d ? PAGE_D : PAGE_L)[P.pageStyle] || PAGE_L[0];
  root.dataset.theme = d ? 'dark' : 'light'; root.lang = DE_UI ? 'de' : 'ar'; root.dir = DE_UI ? 'ltr' : 'rtl'; document.title = TR('القرآن الكريم', 'Der edle Koran');
  root.style.setProperty('--page', bg); root.style.setProperty('--ink', ink);
  root.style.setProperty('--qfs', P.font + 'px'); root.style.setProperty('--qlh', P.line);
  root.style.setProperty('--af', ayahFont()); root.style.setProperty('--bga', P.bgAlpha);
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
  `<header class="hdr"><button class="ib" data-act="back" aria-label="${TR('رجوع', 'Zurück')}">${ic('back')}</button><div class="rtitle"><b>${title}</b>${sub ? `<small>${sub}</small>` : ''}</div>${right}</header>`;
const sw = k => `<label class="sw"><input type="checkbox" data-sw="${k}" ${P[k] ? 'checked' : ''}><span></span></label>`;
const seg = (k, opts, cls = '') => `<div class="seg ${cls}">${opts.map(([v, l]) => `<button data-set="${k}" data-v='${JSON.stringify(v)}' class="${P[k] === v ? 'on' : ''}">${l}</button>`).join('')}</div>`;

/* router */
let route = '', inApp = 0;
const go = h => { inApp++; location.hash = h; };
function back() { if (inApp > 0 && history.length > 1) { inApp--; history.back(); } else location.hash = 'home'; }
function render() {
  const [name, arg] = (location.hash.slice(1) || 'home').split('/');
  if (route === 'read' && name !== 'read' && !P.keepPlaying) stopAudio();
  if (name !== 'read') setFull(false);
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
    <button class="ib" data-go="downloads" aria-label="${TR('التنزيلات', 'Downloads')}">${ic('download')}</button>
    <h1 class="title q">${TR('القرآن الكريم', 'Der edle Koran')}</h1>
    <button class="ib" data-act="jump" aria-label="${TR('انتقال إلى صفحة', 'Zu Seite springen')}"><b>#</b></button>
    <button class="ib" data-go="settings" aria-label="${TR('الإعدادات', 'Einstellungen')}">${ic('settings')}</button>
  </header>
  <section class="hero">
    <div class="hero-k">${TR('متابعة القراءة', 'Weiterlesen')}</div>
    <div class="hero-s q">${sname(last.s)}</div>
    <div class="hero-m">${TR('الجزء', 'Teil')} ${AR(t[1])} • ${TR('الصفحة', 'Seite')} ${AR(last.page)} • ${rname(rec(P.reciter))}</div>
    <button class="btn light" data-go="read/${last.page}">${ic('book')} ${TR('افتح المصحف', 'Mushaf öffnen')}</button>
  </section>
  <div class="quick">
    <button class="qc" data-go="prayer">${ic('clock')}<div><b>${TR('مواقيت الصلاة', 'Gebetszeiten')}</b><small>${Prayer.homeLine()}</small></div></button>
    <button class="qc" data-go="qibla">${ic('compass')}<div><b>${TR('القبلة', 'Qibla')}</b><small>${TR('البوصلة', 'Kompass')}</small></div></button>
  </div>
  <button class="qc wide" data-go="studio">${ic('movie')}<div><b>${TR('استوديو الفيديو', 'Video-Studio')}</b><small>${TR('اصنع فيديو تلاوة بخلفية طبيعية', 'Rezitationsvideo mit Naturhintergrund erstellen')}</small></div></button>
  <div id="install"></div>
  <nav class="tabs">${[TR('السور', 'Suren'), TR('الأجزاء', 'Teile'), TR('العلامات', 'Lesezeichen')].map((x, i) => `<button data-tab="${i}" class="${i === homeTab ? 'on' : ''}">${x}</button>`).join('')}</nav>
  <div id="list"></div>`;
  renderList(); installHint();
}
function renderList() {
  const L = $('#list'); if (!L) return;
  if (homeTab === 0) L.innerHTML = QD.surahs.map(s => `<button class="row" data-go="read/${s.ayahs[0][2]}"><span class="num">${AR(s.n)}</span><span class="rt"><span class="q nm">${sname(s.n)}</span><small>${s.en} • ${s.type === 'Meccan' ? TR('مكية', 'mekkanisch') : TR('مدنية', 'medinensisch')} • ${AR(s.ayahs.length)} ${TR('آية', 'Verse')}</small></span><span class="pg">${TR('ص', 'S.')} ${AR(s.ayahs[0][2])}</span></button>`).join('');
  else if (homeTab === 1) L.innerHTML = juzStart.slice(1).map((j, i) => `<button class="row" data-go="read/${j.page}"><span class="num">${AR(i + 1)}</span><span class="rt"><b>${TR('الجزء', 'Teil')} ${AR(i + 1)}</b><small><span class="q">${sname(j.s)}</span> — ${TR('الآية', 'Vers')} ${AR(j.a)}</small></span><span class="pg">${TR('ص', 'S.')} ${AR(j.page)}</span></button>`).join('');
  else L.innerHTML = marks.length ? marks.map(k => { const [s, a] = k.split(':').map(Number); const t = ay(s, a); return `<button class="row" data-go="read/${t[2]}"><span class="num">${ic('bm')}</span><span class="rt"><span class="q nm">${sname(s)} — ${AR(a)}</span><small class="q">${esc(t[0].split(' ').slice(0, 8).join(' '))}…</small></span><span class="pg">${TR('ص', 'S.')} ${AR(t[2])}</span></button>`; }).join('')
    : `<div class="empty">${TR('لا توجد علامات بعد.', 'Noch keine Lesezeichen.')}<br>${TR('اضغط على آية في المصحف ثم زر العلامة.', 'Tippe im Mushaf auf einen Vers und dann auf das Lesezeichen-Symbol.')}</div>`;
}
function installHint() {
  const el = $('#install'); if (!el) return;
  const standalone = matchMedia('(display-mode: standalone)').matches || navigator.standalone;
  if (standalone || load('hideInstall', false)) { el.innerHTML = ''; return; }
  const ios = /iphone|ipad|ipod/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (ios) el.innerHTML = `<div class="tip">${ic('share')}<span>${TR('لتثبيت التطبيق على الآيفون: افتح الموقع في سفاري، اضغط زر المشاركة ثم «إضافة إلى الشاشة الرئيسية».', 'So installierst du die App auf dem iPhone: in Safari öffnen, auf „Teilen“ tippen, dann „Zum Home-Bildschirm“.')}</span><button data-act="hideInstall" aria-label="${TR('إخفاء', 'Ausblenden')}">${ic('close')}</button></div>`;
  else if (deferredPrompt) el.innerHTML = `<div class="tip">${ic('download')}<span>${TR('ثبّت التطبيق على جهازك', 'App auf dem Gerät installieren')}</span><button class="btn sm" data-act="install">${TR('تثبيت', 'Installieren')}</button></div>`;
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
    res = await fetchAudio(r, s, a);
    await c?.put(url, res.clone()).catch(() => {});
  }
  return new Blob([await res.arrayBuffer()], { type: 'audio/mpeg' });
}
async function ensureCached(r, s, a) {
  const url = audioUrl(r, s, a), c = await caches.open(AC);
  if (await c.match(url)) return;
  await c.put(url, await fetchAudio(r, s, a));
}
const audioErr = e => e.message === 'missing' ? TR('تلاوة هذه الآية غير متوفرة لهذا القارئ', 'Für diesen Vers gibt es keine Rezitation dieses Rezitators') : TR('تعذر تحميل التلاوة. تحقق من الاتصال بالإنترنت', 'Rezitation konnte nicht geladen werden. Bitte Internetverbindung prüfen.');
function nextAyah({ s, a }) { if (a < QD.surahs[s - 1].ayahs.length) return { s, a: a + 1 }; return s < 114 ? { s: s + 1, a: 1 } : null; }
function prevAyah({ s, a }) { if (a > 1) return { s, a: a - 1 }; return s > 1 ? { s: s - 1, a: QD.surahs[s - 2].ayahs.length } : null; }
function playAyah(s, a) { AU.cur = { s, a }; AU.rep = 0; startCur(); }
async function startCur() {
  const tok = ++AU.tok, { s, a } = AU.cur;
  AU.loading = true; renderBar(); markPlaying(true);
  try {
    const blob = await audioBlob(P.reciter, s, a).catch(e => { if (e.message === 'missing' || rec(P.reciter).sb) throw e; return null; });
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
    toast(e.name === 'NotAllowedError' ? TR('اضغط زر التشغيل للمتابعة', 'Zum Fortfahren auf Abspielen tippen') : audioErr(e), TR('إعادة المحاولة', 'Erneut versuchen'), () => { unlockAudio(); startCur(); });
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
  navigator.mediaSession.metadata = new MediaMetadata({ title: `${sname(AU.cur.s).replace(/[\u064B-\u0652\u0670\u06DF-\u06ED]/g, '')} — ${TR('الآية', 'Vers')} ${AR(AU.cur.a)}`, artist: rname(rec(P.reciter)), album: TR('القرآن الكريم', 'Der edle Koran'), artwork: [{ src: 'icons/icon-512.png', sizes: '512x512', type: 'image/png' }] });
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
      out += `<div class="sh"><span>${QD.surahs[s - 1].name}</span></div>`;
      if (s !== 1 && s !== 9) out += `<div class="bas">${basm()}</div>`;
    }
    const span = `<span class="ay" data-k="${s}:${a}">${atext(s, a)}<span class="mk">&nbsp;${mark(a)}</span></span> `;
    const de = P.de === 2 && DE;
    if (de || P.tafsirUnder) out += `<p>${span}</p>${de ? `<p class="de" dir="ltr" lang="de">${esc(deText(s, a))}</p>` : ''}${P.tafsirUnder ? `<div class="tfu" data-tk="${s}:${a}"></div>` : ''}`;
    else para += span;
  }
  return out + (para ? `<p>${para}</p>` : '');
}
function renderReader(p) {
  p = Math.min(604, Math.max(1, p | 0)); curPage = p; route = 'read';
  if (P.de && !DE) loadDE();
  const [fs, fa] = pages[p][0], first = ay(fs, fa);
  last = { page: p, s: fs, a: fa }; save('last', last);
  $('#view').innerHTML = `
  ${header(`<span class="q">${sname(fs)}</span>`, `${TR('الجزء', 'Teil')} ${AR(first[1])} • ${TR('الصفحة', 'Seite')} ${AR(p)}`, `<button class="ib" data-act="full" aria-label="${TR('ملء الشاشة', 'Vollbild')}">${ic('full')}</button><button class="ib" data-go="settings" aria-label="${TR('الإعدادات', 'Einstellungen')}">${ic('settings')}</button>`)}
  <div class="fsx"><button data-act="full">${ic('fullx')}<span>${TR('الخروج من ملء الشاشة', 'Vollbild beenden')}</span></button><small>${AR(p)}</small></div>
  <div class="page-wrap"><article class="page ${flipDir ? (flipDir > 0 ? 'flip-n' : 'flip-p') : ''}" id="page">${pageHtml(p)}</article>
  <div class="pager"><button class="ib" data-act="turn" data-d="-1" aria-label="${TR('الصفحة السابقة', 'Vorherige Seite')}" ${p === 1 ? 'disabled' : ''}>${ic('chr')}</button><span>${AR(p)} / ${AR(604)}</span><button class="ib" data-act="turn" data-d="1" aria-label="${TR('الصفحة التالية', 'Nächste Seite')}" ${p === 604 ? 'disabled' : ''}>${ic('chl')}</button></div></div>
  <div id="bar" class="bar"></div>`;
  const pw = $('.page-wrap'); let sx = 0, sy = 0;
  pw.addEventListener('touchstart', e => { sx = e.touches[0].clientX; sy = e.touches[0].clientY; }, { passive: true });
  pw.addEventListener('touchend', e => { const dx = e.changedTouches[0].clientX - sx, dy = e.changedTouches[0].clientY - sy; if (Math.abs(dx) > 70 && Math.abs(dx) > Math.abs(dy) * 1.5) turn(dx > 0 ? 1 : -1); });
  flipDir = 0;
  let lt = null, lx = 0, ly = 0;
  const lpCancel = () => { clearTimeout(lt); lt = null; };
  pw.addEventListener('touchstart', e => {
    const el = e.target.closest('.ay'); lpCancel(); if (!el || e.touches.length > 1) return;
    lx = e.touches[0].clientX; ly = e.touches[0].clientY;
    lt = setTimeout(() => { lt = null; longPress(el); }, 550);
  }, { passive: true });
  pw.addEventListener('touchmove', e => { if (lt && Math.hypot(e.touches[0].clientX - lx, e.touches[0].clientY - ly) > 10) lpCancel(); }, { passive: true });
  pw.addEventListener('touchend', lpCancel, { passive: true });
  pw.addEventListener('contextmenu', e => { const el = e.target.closest('.ay'); if (el) { e.preventDefault(); longPress(el); } });
  renderBar(); markPlaying(false); acquireWake();
  if (P.tafsirUnder) fillTafsirUnder();
}
let flipDir = 0, lpAt = 0;
function longPress(el) {
  if (Date.now() - lpAt < 800) return;
  lpAt = Date.now(); navigator.vibrate?.(15);
  const [s, a] = el.dataset.k.split(':').map(Number); showTafsir(s, a);
}
function setFull(on) {
  document.body.classList.toggle('full', on);
  const d = document;
  if (on) d.documentElement.requestFullscreen?.().catch(() => {});
  else if (d.fullscreenElement) d.exitFullscreen?.().catch(() => {});
}
function turn(d) { const p = curPage + d; if (p < 1 || p > 604) return; if (P.pageFlip) flipDir = d; history.replaceState(null, '', '#read/' + p); renderReader(p); }
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
  if (!k) { b.innerHTML = `<div class="hint">${TR('اضغط على أي آية للاستماع بصوت', 'Tippe auf einen Vers, um ihn zu hören – Rezitator:')} ${rname(rec(P.reciter))}</div>`; return; }
  const [s, a] = k.split(':').map(Number), on = AU.playing || AU.loading;
  b.innerHTML = `${P.de === 1 && DE && a > 0 ? `<div class="bub" dir="ltr" lang="de">${esc(deText(s, a))}</div>` : ''}<div class="bi"><b class="q">${sname(s)}</b><small>${TR('الآية', 'Vers')} ${AR(a)} • ${rname(rec(P.reciter))}${AU.loading ? TR(' • جارٍ التحميل…', ' • wird geladen…') : ''}</small><button class="tfbtn" data-act="tafsir" data-k="${k}">${ic('book')}${TR('التفسير', 'Tafsir')}</button></div>
  <div class="bc">
    <button class="ib" data-act="bm" data-k="${k}" aria-label="${TR('علامة', 'Lesezeichen')}">${ic(marks.includes(k) ? 'bm' : 'bmo')}</button>
    <button class="ib" data-act="speed" aria-label="${TR('السرعة', 'Geschwindigkeit')}"><b style="font-size:14px">${AR(P.speed)}×</b></button>
    <button class="ib" data-act="prevA" aria-label="${TR('الآية السابقة', 'Vorheriger Vers')}">${ic('prev', 'mir')}</button>
    <button class="fab" data-act="toggle" aria-label="${on ? TR('إيقاف مؤقت', 'Pause') : TR('تشغيل', 'Abspielen')}">${ic(on ? 'pause' : 'play')}</button>
    <button class="ib" data-act="nextA" aria-label="${TR('الآية التالية', 'Nächster Vers')}">${ic('next', 'mir')}</button>
    <button class="ib ${P.repeat > 1 ? 'on' : ''}" data-act="repeat" aria-label="${TR('التكرار', 'Wiederholen')}">${ic('repeat')}${P.repeat > 1 ? `<sup>${AR(P.repeat)}</sup>` : ''}</button>
    <button class="ib" data-act="stop" aria-label="${TR('إيقاف', 'Stopp')}">${ic('stop')}</button>
  </div>`;
}

/* settings */
function renderSettings() {
  route = 'settings';
  const y = window.scrollY;
  $('#view').innerHTML = `${header(TR('الإعدادات', 'Einstellungen'))}
  <div class="pad">
    <section class="card"><h3>${TR('اللغة', 'Sprache')} • Language</h3>${seg('lang', [['ar', 'العربية'], ['de', 'Deutsch']])}<small>${TR('Deutsch: التطبيق كله بالألمانية (نص القرآن يبقى بالعربية)', 'Die ganze App auf Deutsch (der Korantext bleibt Arabisch)')}</small></section>
    <section class="card"><h3>${TR('القارئ', 'Rezitator')}</h3><select data-sel="reciter" aria-label="${TR('القارئ', 'Rezitator')}">${RECITERS.map(r => `<option value="${r.id}" ${r.id === rec(P.reciter).id ? 'selected' : ''}>${rname(r)}</option>`).join('')}</select></section>
    <section class="card"><h3>${TR('رسم المصحف', 'Schrift')}</h3>${seg('script', SCRIPTS.map((x, i) => [i, x[0]]), 'col')}
      ${SCRIPTS[P.script]?.[2] ? '' : `<h3>${TR('خط المصحف', 'Schriftart')}</h3>${seg('qfont', QFONTS.map((f, i) => [i, `<span style="font-family:${f[0]},serif">${f[1]}</span>`]))}`}</section>
    <section class="card"><h3>${TR('المظهر', 'Design')}</h3>${seg('theme', [['system', TR('تلقائي', 'Automatisch')], ['light', TR('فاتح', 'Hell')], ['dark', TR('داكن', 'Dunkel')]])}
      <h3>${TR('لون الصفحة', 'Seitenfarbe')}</h3>${seg('pageStyle', PAGE_STYLES.map((n, i) => [i, `<i class="sw4" style="background:${(isDark() ? PAGE_D : PAGE_L)[i][0]}"></i>${n}`]))}
      <h3>${TR('حجم الخط', 'Schriftgröße')}</h3><input type="range" data-rng="font" min="20" max="48" step="1" value="${P.font}">
      <h3>${TR('تباعد الأسطر', 'Zeilenabstand')}</h3><input type="range" data-rng="line" min="1.5" max="2.6" step="0.1" value="${P.line}">
      <div class="sample">${basm()}</div>
      <h3>${TR('وضوح خلفية التطبيق', 'Sichtbarkeit des App-Hintergrunds')}</h3><input type="range" data-rng="bgAlpha" min="0" max="0.7" step="0.05" value="${P.bgAlpha}">
      <div class="rowx"><span>${TR('قلب الصفحات مثل المصحف', 'Umblättern wie im Mushaf')}<small>${TR('تأثير الورق عند الانتقال بين الصفحات', 'Papiereffekt beim Seitenwechsel')}</small></span>${sw('pageFlip')}</div></section>
    <section class="card"><h3>${TR('التفسير', 'Tafsir')}</h3><small>${TR('اضغط مطولاً على أي آية (أو زر «التفسير» في شريط التلاوة) لعرض تفسيرها.', 'Lange auf einen Vers drücken (oder „Tafsir“ in der Wiedergabeleiste), um die Erklärung zu sehen. Der Tafsir ist auf Arabisch.')}</small>
      ${seg('tafsir', TAFSIRS.map((t, i) => [i, t[0] + (i === 0 ? TR(' • بدون إنترنت', ' • offline') : '')]), 'col')}
      <div class="rowx"><span>${TR('عرض التفسير تحت كل آية', 'Tafsir unter jedem Vers anzeigen')}</span>${sw('tafsirUnder')}</div></section>
    <section class="card"><h3>${TR('التلاوة', 'Rezitation')}</h3>
      <div class="rowx"><span>${TR('سرعة التلاوة', 'Wiedergabegeschwindigkeit')}</span></div>${seg('speed', [0.75, 1, 1.25, 1.5, 2].map(v => [v, AR(v) + '×']))}
      <div class="rowx"><span>${TR('تكرار كل آية', 'Jeden Vers wiederholen')}</span></div>${seg('repeat', [[1, TR('بدون', 'Aus')], ...[2, 3, 5, 10].map(v => [v, AR(v)])])}
      <div class="rowx"><span>${TR('تشغيل متواصل', 'Fortlaufende Wiedergabe')}<small>${TR('الانتقال تلقائياً إلى الآية التالية', 'Automatisch zum nächsten Vers')}</small></span>${sw('continuous')}</div>
      <div class="rowx"><span>${TR('متابعة الآية المقروءة', 'Aktuellem Vers folgen')}<small>${TR('تقليب الصفحة تلقائياً مع التلاوة', 'Seite automatisch mit der Rezitation umblättern')}</small></span>${sw('follow')}</div>
      <div class="rowx"><span>${TR('متابعة التلاوة بعد الخروج من المصحف', 'Rezitation nach Verlassen des Mushaf fortsetzen')}</span>${sw('keepPlaying')}</div>
      <div class="rowx"><span>${TR('إبقاء الشاشة مضاءة أثناء القراءة', 'Bildschirm beim Lesen anlassen')}</span>${sw('wake')}</div></section>
    <section class="card"><h3>${TR('الترجمة الألمانية (Deutsch)', 'Deutsche Übersetzung')}</h3>${seg('de', [[0, TR('إيقاف', 'Aus')], [1, TR('فقاعة', 'Sprechblase')], [2, TR('تحت كل آية', 'Unter jedem Vers')]])}
      <div class="rowx"><span><small>${TR('فقاعة: تظهر الترجمة عند الضغط على الآية • تحت كل آية: عرض مقسوم عربي / ألماني', 'Sprechblase: Übersetzung erscheint beim Antippen eines Verses • Unter jedem Vers: geteilte Ansicht Arabisch / Deutsch')}<br>Übersetzung: Bubenheim &amp; Elyas</small></span></div></section>
    <section class="card"><h3>${TR('عن التطبيق', 'Über die App')}</h3><div class="rowx"><span>${TR('المطور: محمد صالح المحمد<small>Entwickler: Mouhamad Almuhamad</small>', 'Entwickler: Mouhamad Almuhamad<small>المطور: محمد صالح المحمد</small>')}</span></div></section>
    <section class="card"><h3>${TR('حول', 'Quellen')}</h3><small>${TR('نص القرآن: مجمع الملك فهد لطباعة المصحف الشريف (الخط والنص العثماني) عبر <a href="https://quran.com" target="_blank" rel="noopener">Quran.com</a>، و<a href="https://tanzil.net" target="_blank" rel="noopener">Tanzil Project</a> (CC BY 3.0). التلاوات: <a href="https://everyayah.com" target="_blank" rel="noopener">EveryAyah.com</a> و<a href="https://mp3quran.net" target="_blank" rel="noopener">mp3quran.net</a>. التفاسير: التفسير الميسر، <a href="https://alquran.cloud" target="_blank" rel="noopener">alquran.cloud</a>، <a href="https://quran.com" target="_blank" rel="noopener">Quran.com</a>. مواقيت الصلاة: مكتبة Adhan (MIT).', 'Korantext: King-Fahd-Komplex zum Druck des Heiligen Koran (Uthmani-Schrift und -Text) über <a href="https://quran.com" target="_blank" rel="noopener">Quran.com</a> und <a href="https://tanzil.net" target="_blank" rel="noopener">Tanzil Project</a> (CC BY 3.0). Rezitationen: <a href="https://everyayah.com" target="_blank" rel="noopener">EveryAyah.com</a> und <a href="https://mp3quran.net" target="_blank" rel="noopener">mp3quran.net</a>. Tafsir: Tafsir al-Muyassar, <a href="https://alquran.cloud" target="_blank" rel="noopener">alquran.cloud</a>, <a href="https://quran.com" target="_blank" rel="noopener">Quran.com</a>. Gebetszeiten: Adhan-Bibliothek (MIT). Übersetzung: Bubenheim &amp; Elyas.')}</small></section>
  </div>`;
  window.scrollTo(0, y);
}
function onPref(k) {
  if (k === 'lang') { if (P.lang === 'de' && !P.de) { P.de = 2; save('prefs', P); } location.reload(); return; }
  if (k === 'de' && P.de) loadDE();
  if (k === 'script') loadScript(P.script).then(() => { applyTheme(); if (route === 'settings') renderSettings(); }).catch(() => { toast(TR('تعذر تحميل الرسم. تحقق من الاتصال بالإنترنت', 'Schrift konnte nicht geladen werden. Bitte Internetverbindung prüfen.')); setP('script', 1); });
  if ((k === 'tafsir' || k === 'tafsirUnder') && route === 'read' && P.tafsirUnder) renderReader(curPage);
  if (k === 'tafsirUnder' && route === 'read' && !P.tafsirUnder) renderReader(curPage);
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
  $('#view').innerHTML = `${header(TR('التنزيلات', 'Downloads'), rname(rec(P.reciter)))}
  <div class="pad"><div class="card"><p class="note">${TR('نزّل السور للاستماع بدون إنترنت. يمكن تغيير القارئ من الإعدادات. كل آية تستمع إليها تحفظ تلقائياً أيضاً.', 'Lade Suren herunter, um offline zu hören. Den Rezitator änderst du in den Einstellungen. Jeder gehörte Vers wird auch automatisch gespeichert.')}</p>
    <div class="btns"><button class="btn" data-act="dlAll">${ic('download')} ${TR('تنزيل القرآن كاملاً', 'Ganzen Koran herunterladen')}</button>${DL.cur || DL.q.length ? `<button class="btn ghost" data-act="dlCancel">${TR('إلغاء', 'Abbrechen')}</button>` : ''}</div>
    ${DL.cur ? `<small>${TR('جارٍ تنزيل', 'Lade')} <span class="q">${sname(DL.cur)}</span> ${AR(DL.done)}/${AR(DL.total)}${DL.q.length ? ` • ${AR(DL.q.length)} ${TR('في الانتظار', 'wartend')}` : ''}</small><div class="prog"><i style="width:${DL.total ? DL.done / DL.total * 100 : 0}%"></i></div>` : ''}</div>
  <div>${QD.surahs.map(s => `<div class="dlr"><span class="num">${AR(s.n)}</span><span class="rt"><span class="q nm">${sname(s.n)}</span><small>${AR(s.ayahs.length)} ${TR('آية', 'Verse')}</small></span>${done.includes(s.n) ? `${ic('check')}<button class="ib" data-act="dlDel" data-n="${s.n}" aria-label="${TR('حذف', 'Löschen')}">${ic('del')}</button>` : DL.cur === s.n || DL.q.includes(s.n) ? `<small>${DL.cur === s.n ? AR(Math.round(DL.done / Math.max(1, DL.total) * 100)) + TR('٪', '%') : TR('في الانتظار', 'wartend')}</small>` : `<button class="ib" data-act="dl" data-n="${s.n}" aria-label="${TR('تنزيل', 'Herunterladen')}">${ic('download')}</button>`}</div>`).join('')}</div></div>`;
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
    if (failed) { toast(audioErr(failed), TR('إعادة المحاولة', 'Erneut versuchen'), () => enqueue([n])); DL.q = []; }
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
    const m = modal(`<h3>${TR('انتقال إلى صفحة', 'Zu Seite springen')}</h3><input type="number" inputmode="numeric" min="1" max="604" placeholder="${AR(1)} – ${AR(604)}" id="jp"><div class="acts"><button class="btn ghost" data-close>${TR('إلغاء', 'Abbrechen')}</button><button class="btn" id="jgo">${TR('انتقال', 'Los')}</button></div>`);
    const i = $('#jp', m); i.focus();
    const ok = () => { const p = parseInt(String(i.value).replace(/[٠-٩]/g, d => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)), 10); if (p >= 1 && p <= 604) { m.remove(); go('read/' + p); } else toast(TR('أدخل رقم صفحة من ١ إلى ٦٠٤', 'Seitenzahl von 1 bis 604 eingeben')); };
    $('#jgo', m).onclick = ok; i.onkeydown = e => { if (e.key === 'Enter') ok(); };
  },
  turn(el) { turn(+el.dataset.d); }, toggle: togglePlay, stop: stopAudio,
  full() { setFull(!document.body.classList.contains('full')); },
  tafsir(el) { const [s, a] = el.dataset.k.split(':').map(Number); if (a > 0) showTafsir(s, a); },
  prevA: () => step(-1), nextA: () => step(1),
  speed() { const L = [0.75, 1, 1.25, 1.5, 2]; setP('speed', L[(L.indexOf(P.speed) + 1) % L.length]); renderBar(); },
  repeat() { const L = [1, 2, 3, 5, 10]; setP('repeat', L[(L.indexOf(P.repeat) + 1) % L.length]); renderBar(); },
  bm(el) { const k = el.dataset.k; marks = marks.includes(k) ? marks.filter(x => x !== k) : [...marks, k]; save('marks', marks); toast(marks.includes(k) ? TR('تمت إضافة العلامة', 'Lesezeichen gesetzt') : TR('تمت إزالة العلامة', 'Lesezeichen entfernt')); renderBar(); },
  hideInstall() { save('hideInstall', true); installHint(); },
  async install() { if (!deferredPrompt) return; deferredPrompt.prompt(); await deferredPrompt.userChoice; deferredPrompt = null; installHint(); },
  dl(el) { enqueue([+el.dataset.n]); }, dlDel(el) { deleteSurah(+el.dataset.n); },
  dlAll() { if (confirm(TR('تنزيل القرآن كاملاً يحتاج مساحة كبيرة (قرابة ١ جيجابايت). هل تريد المتابعة؟', 'Der ganze Koran braucht viel Speicherplatz (ca. 1 GB). Fortfahren?'))) enqueue(QD.surahs.map(s => s.n)); },
  dlCancel() { DL.cancel = true; DL.q = []; renderDownloads(); },
};
document.addEventListener('click', e => {
  const t = e.target;
  const ayEl = t.closest('.ay');
  if (ayEl && route === 'read') { if (Date.now() - lpAt < 800) return; unlockAudio(); const k = ayEl.dataset.k; selKey = k; const [s, a] = k.split(':').map(Number); playAyah(s, a); return; }
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
  try { await loadData(); await loadScript(P.script).catch(() => { SC = null; }); applyTheme(); } catch { $('#view').innerHTML = `<div class="empty">${TR('تعذر تحميل بيانات القرآن. تحقق من الاتصال ثم', 'Korandaten konnten nicht geladen werden. Verbindung prüfen und')} <a href="">${TR('أعد المحاولة', 'erneut versuchen')}</a>.</div>`; return; }
  render(); Prayer.init();
  const sp = $('#splash'); if (sp) setTimeout(() => { sp.classList.add('out'); setTimeout(() => sp.remove(), 300); }, Math.max(0, 1500 - performance.now()));
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
}
document.addEventListener('DOMContentLoaded', init);
