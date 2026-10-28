'use strict';
const METHODS = [['MuslimWorldLeague', TR('رابطة العالم الإسلامي', 'Muslimische Weltliga')], ['UmmAlQura', TR('أم القرى (مكة المكرمة)', 'Umm al-Qura (Mekka)')], ['Egyptian', TR('الهيئة المصرية العامة للمساحة', 'Ägyptische Vermessungsbehörde')], ['Karachi', TR('جامعة العلوم الإسلامية، كراتشي', 'Universität für Islamwissenschaften, Karatschi')], ['Dubai', TR('دبي', 'Dubai')], ['Kuwait', TR('الكويت', 'Kuwait')], ['Qatar', TR('قطر', 'Katar')], ['Singapore', TR('سنغافورة', 'Singapur')], ['NorthAmerica', TR('أمريكا الشمالية (ISNA)', 'Nordamerika (ISNA)')], ['MoonsightingCommittee', TR('لجنة رؤية الهلال', 'Mondsichtungskomitee')]];
const PR_NAMES = { fajr: TR('الفجر', 'Fadschr'), sunrise: TR('الشروق', 'Sonnenaufgang'), dhuhr: TR('الظهر', 'Dhuhr'), asr: TR('العصر', 'Asr'), maghrib: TR('المغرب', 'Maghrib'), isha: TR('العشاء', 'Ischa') };
const PR_ORDER = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

const Prayer = (() => {
  let loc = load('loc', null), timer = 0, ntimer = 0, locating = false;
  const coords = () => new adhan.Coordinates(loc.lat, loc.lon);
  function params() {
    const p = (adhan.CalculationMethod[P.method] || adhan.CalculationMethod.MuslimWorldLeague)();
    p.madhab = P.hanafi ? adhan.Madhab.Hanafi : adhan.Madhab.Shafi;
    if (Math.abs(loc.lat) > 48) p.highLatitudeRule = adhan.HighLatitudeRule.recommended ? adhan.HighLatitudeRule.recommended(coords()) : adhan.HighLatitudeRule.SeventhOfTheNight;
    return p;
  }
  const times = (d = new Date()) => new adhan.PrayerTimes(coords(), d, params());
  const fmt = d => { if (DE_UI) return d.toTimeString().slice(0, 5); let h = d.getHours(); const m = d.getMinutes(), pm = h >= 12; h = h % 12 || 12; return `${AR(h)}:${AR(String(m).padStart(2, '0'))} ${pm ? 'م' : 'ص'}`; };
  function next() {
    const now = new Date(), t = times(now);
    for (const k of PR_ORDER) if (k !== 'sunrise' && t[k] > now) return { k, at: t[k], today: true };
    const tm = new Date(now); tm.setDate(tm.getDate() + 1);
    return { k: 'fajr', at: times(tm).fajr, today: false };
  }
  const homeLine = () => loc ? (() => { const n = next(); return `${PR_NAMES[n.k]} ${fmt(n.at)}`; })() : TR('حدد موقعك', 'Standort festlegen');
  const place = () => loc.city || `${loc.lat.toFixed(3)}${TR("، ", ", ")}${loc.lon.toFixed(3)}`;
  async function cityName(lat, lon) {
    try { const r = await fetch(`https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lon}&localityLanguage=ar`); const j = await r.json(); return j.city || j.locality || j.principalSubdivision || ''; } catch { return ''; }
  }
  function locate() {
    if (locating) return Promise.resolve(false);
    if (!navigator.geolocation) { toast(TR('هذا الجهاز لا يدعم تحديد الموقع', 'Dieses Gerät unterstützt keine Standortbestimmung')); return Promise.resolve(false); }
    locating = true; if (route === 'prayer') fill();
    return new Promise(res => navigator.geolocation.getCurrentPosition(async p => {
      loc = { lat: p.coords.latitude, lon: p.coords.longitude, city: '' }; save('loc', loc);
      loc.city = await cityName(loc.lat, loc.lon); save('loc', loc);
      locating = false; schedule(); after(); res(true);
    }, e => {
      locating = false; toast(e.code === 1 ? TR('يلزم السماح بالوصول إلى الموقع من إعدادات المتصفح', 'Bitte Standortzugriff in den Browser-Einstellungen erlauben') : TR('تعذر تحديد الموقع، حاول مجدداً', 'Standort konnte nicht bestimmt werden, bitte erneut versuchen')); after(); res(false);
    }, { enableHighAccuracy: false, timeout: 20000, maximumAge: 600000 }));
  }
  function after() { if (route === 'prayer') fill(); if (route === 'qibla') Qibla.render($('#view')); }
  function render(v) {
    route = 'prayer';
    const d = new Date();
    let hijri = ''; try { hijri = new Intl.DateTimeFormat(TR('ar-SA-u-ca-islamic-umalqura', 'de-DE-u-ca-islamic-umalqura'), { day: 'numeric', month: 'long', year: 'numeric' }).format(d); } catch {}
    v.innerHTML = `${header(TR('مواقيت الصلاة', 'Gebetszeiten'), hijri)}<div class="pad" id="pr"></div>`;
    fill();
    clearInterval(timer); timer = setInterval(() => { if (route !== 'prayer') { clearInterval(timer); return; } tick(); }, 1000);
  }
  function fill() {
    const el = $('#pr'); if (!el) return;
    if (!loc) {
      el.innerHTML = `<div class="card center">${ic('pin', 'big')}<p>${TR('نحتاج موقعك لحساب مواقيت الصلاة بدقة. الحساب يتم على جهازك ويعمل بدون إنترنت.', 'Wir brauchen deinen Standort, um die Gebetszeiten genau zu berechnen. Die Berechnung erfolgt auf deinem Gerät und funktioniert offline.')}</p><button class="btn" data-act="locate" ${locating ? 'disabled' : ''}>${locating ? TR('جارٍ تحديد الموقع…', 'Standort wird bestimmt…') : TR('تحديد موقعي', 'Meinen Standort bestimmen')}</button></div>`;
      return;
    }
    const t = times(), n = next();
    el.innerHTML = `
    <section class="hero sm"><div class="hero-k">${TR('الصلاة القادمة', 'Nächstes Gebet')}</div><div class="hero-s">${PR_NAMES[n.k]} <span>${fmt(n.at)}</span></div><div class="cd" id="cd"></div>
      <div class="hero-m">${ic('pin')} ${esc(place())} • <button class="lnk" data-act="locate">${locating ? TR('جارٍ التحديث…', 'Wird aktualisiert…') : TR('تحديث الموقع', 'Standort aktualisieren')}</button></div></section>
    <div class="card">${PR_ORDER.map(k => `<div class="pt ${n.today && k === n.k ? 'on' : ''}"><span>${PR_NAMES[k]}</span><b>${fmt(t[k])}</b></div>`).join('')}</div>
    <div class="card"><h3>${TR('طريقة الحساب', 'Berechnungsmethode')}</h3><select data-sel="method">${METHODS.map(([k, l]) => `<option value="${k}" ${P.method === k ? 'selected' : ''}>${l}</option>`).join('')}</select>
      <div class="rowx"><span>${TR('العصر على المذهب الحنفي', 'Asr nach hanafitischer Rechtsschule')}</span>${sw('hanafi')}</div>
      <div class="rowx"><span>${TR('تنبيه عند دخول وقت الصلاة', 'Erinnerung zur Gebetszeit')}<small>${TR('يعمل والتطبيق مفتوح. لا تسمح تطبيقات الويب على الآيفون بالتنبيه والتطبيق مغلق.', 'Funktioniert, solange die App geöffnet ist. Web-Apps auf dem iPhone können bei geschlossener App nicht erinnern.')}</small></span>${sw('notify')}</div></div>`;
    tick();
  }
  function tick() {
    const cd = $('#cd'); if (!cd || !loc) return;
    const ms = next().at - new Date(); if (ms <= 0) { fill(); return; }
    const s = Math.floor(ms / 1000), p2 = x => AR(String(x).padStart(2, '0'));
    cd.textContent = `${TR('بعد', 'in')} ${p2(Math.floor(s / 3600))}:${p2(Math.floor(s / 60) % 60)}:${p2(s % 60)}`;
  }
  function schedule() {
    clearTimeout(ntimer); if (!loc || !P.notify) return;
    const n = next(), ms = n.at - new Date();
    ntimer = setTimeout(async () => {
      const title = `${TR('حان الآن وقت صلاة', 'Jetzt ist Gebetszeit:')} ${PR_NAMES[n.k]}`;
      toast(title);
      try {
        if ('Notification' in window && Notification.permission === 'granted') {
          const reg = await navigator.serviceWorker?.getRegistration();
          if (reg) reg.showNotification(title, { body: place(), icon: 'icons/icon-192.png', tag: 'prayer', lang: 'ar', dir: 'rtl' });
          else new Notification(title, { body: place() });
        }
      } catch {}
      if (route === 'prayer') fill();
      setTimeout(schedule, 2000);
    }, Math.max(0, Math.min(ms, 2 ** 31 - 1)));
  }
  async function refresh(k) {
    if (k === 'notify' && P.notify && 'Notification' in window && Notification.permission === 'default') {
      const r = await Notification.requestPermission();
      if (r !== 'granted') toast(TR('لم يتم السماح بالإشعارات — سيظهر التنبيه داخل التطبيق فقط', 'Benachrichtigungen nicht erlaubt – die Erinnerung erscheint nur in der App'));
    }
    if (route === 'prayer') fill(); schedule();
  }
  document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible') { schedule(); if (route === 'prayer') fill(); } });
  return { render, homeLine, init: schedule, refresh, loc: () => loc, locate, act: { locate } };
})();

const Qibla = (() => {
  let heading = null, shown = null, acc = null, raf = 0, evt = '', noSensor = 0, buzzed = false, active = false;
  const norm = d => ((d % 360) + 360) % 360;
  function render(v) {
    route = 'qibla'; const L = Prayer.loc();
    if (!L) {
      v.innerHTML = `${header(TR('القبلة', 'Qibla'))}<div class="pad"><div class="card center">${ic('pin', 'big')}<p>${TR('نحتاج موقعك لحساب اتجاه القبلة.', 'Wir brauchen deinen Standort, um die Qibla-Richtung zu berechnen.')}</p><button class="btn" data-act="locate">${TR('تحديد موقعي', 'Meinen Standort bestimmen')}</button></div></div>`;
      return;
    }
    const q = adhan.Qibla(new adhan.Coordinates(L.lat, L.lon));
    const ticks = Array.from({ length: 72 }, (_, i) => `<i class="tick ${i % 6 ? '' : 'l'}" style="transform:rotate(${i * 5}deg)"></i>`).join('');
    const labs = [[TR('ش', 'N'), 0, 'n'], [TR('ق', 'O'), 90, ''], [TR('ج', 'S'), 180, ''], [TR('غ', 'W'), 270, '']].map(([l, a, c]) => { const r = a * Math.PI / 180; return `<span class="lab ${c}" style="transform:translate(${Math.sin(r) * 108}px,${-Math.cos(r) * 108}px) rotate(calc(var(--h,0) * 1deg))">${l}</span>`; }).join('');
    const kr = q * Math.PI / 180;
    v.innerHTML = `${header(TR('القبلة', 'Qibla'), esc(L.city || ''))}
    <div class="pad"><div class="compass" id="cmp" dir="ltr"><div class="dial" id="dial">${ticks}${labs}<span class="kaaba" style="transform:translate(${Math.sin(kr) * 92}px,${-Math.cos(kr) * 92}px) rotate(calc(var(--h,0) * 1deg))"><i></i></span></div><div class="needle" id="ndl" style="--d:${q}"></div><div class="phone-top"></div></div>
    <div class="card center"><h3 style="font-size:24px">${AR(Math.round(q))}° ${TR('من الشمال', 'von Norden')}</h3><p id="qg">${TR('اضغط «تشغيل البوصلة» ثم أمسك الهاتف بشكل مسطح ووجّه أعلاه أمامك.', 'Tippe auf „Kompass starten“, halte das Handy flach und richte die Oberseite nach vorne.')}</p>
    <button class="btn" data-act="compass" id="cbtn" ${active ? 'hidden' : ''}>${ic('compass')} ${TR('تشغيل البوصلة', 'Kompass starten')}</button><small id="qacc"></small></div></div>`;
    if (active) loop(q);
    Qibla._q = q;
  }
  async function start() {
    if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
      try { if (await DeviceOrientationEvent.requestPermission() !== 'granted') { $('#qg').textContent = TR('يلزم السماح بالوصول إلى مستشعر الحركة لتشغيل البوصلة.', 'Bitte Zugriff auf den Bewegungssensor erlauben, um den Kompass zu nutzen.'); return; } }
      catch { $('#qg').textContent = TR('تعذر الوصول إلى مستشعر البوصلة.', 'Kein Zugriff auf den Kompasssensor.'); return; }
    }
    active = true; $('#cbtn')?.setAttribute('hidden', '');
    evt = 'ondeviceorientationabsolute' in window ? 'deviceorientationabsolute' : 'deviceorientation';
    window.addEventListener(evt, onOri);
    clearTimeout(noSensor);
    noSensor = setTimeout(() => { if (heading == null && $('#qg')) $('#qg').textContent = `${TR('لا يوجد مستشعر بوصلة في هذا الجهاز. اتجاه القبلة', 'Kein Kompasssensor in diesem Gerät. Qibla-Richtung:')} ${AR(Math.round(Qibla._q))}° ${TR('من الشمال', 'von Norden')} ${TR('— استخدم بوصلة لتحديده.', '– nutze einen Kompass, um sie zu finden.')}`; }, 3000);
    loop(Qibla._q);
  }
  function onOri(e) {
    let h = null;
    if (typeof e.webkitCompassHeading === 'number' && !isNaN(e.webkitCompassHeading)) { h = e.webkitCompassHeading; acc = e.webkitCompassAccuracy; }
    else if ((e.absolute || evt === 'deviceorientationabsolute') && e.alpha != null) h = 360 - e.alpha;
    if (h == null) return;
    heading = norm(h + (screen.orientation?.angle ?? window.orientation ?? 0));
  }
  function loop(q) {
    cancelAnimationFrame(raf);
    const f = () => {
      if (route !== 'qibla') return;
      if (heading != null) {
        shown = shown == null ? heading : norm(shown + (((heading - shown + 540) % 360) - 180) * 0.15);
        const dial = $('#dial'), ndl = $('#ndl'), cmp = $('#cmp'), g = $('#qg');
        dial.style.setProperty('--h', shown); $$('.lab, .kaaba', dial).forEach(x => x.style.setProperty('--h', shown));
        const diff = ((q - shown + 540) % 360) - 180;
        ndl.style.setProperty('--d', diff);
        const ok = Math.abs(diff) < 5; cmp.classList.toggle('ok', ok);
        g.textContent = ok ? TR('أنت متجه نحو القبلة ✓', 'Du bist zur Qibla ausgerichtet ✓') : `${TR('استدر', 'Drehe dich')} ${diff > 0 ? TR('يميناً', 'nach rechts') : TR('يساراً', 'nach links')} ${TR('حوالي', 'um etwa')} ${AR(Math.round(Math.abs(diff)))}°`;
        if (ok && !buzzed) { navigator.vibrate?.(60); buzzed = true; } if (!ok) buzzed = false;
        $('#qacc').textContent = acc != null && (acc < 0 || acc > 25) ? TR('دقة البوصلة منخفضة: حرّك الهاتف على شكل رقم ٨ للمعايرة وابتعد عن المعادن.', 'Geringe Kompassgenauigkeit: Handy in Form einer 8 bewegen und von Metall fernhalten.') : '';
      }
      raf = requestAnimationFrame(f);
    };
    raf = requestAnimationFrame(f);
  }
  function leave() { cancelAnimationFrame(raf); if (evt) window.removeEventListener(evt, onOri); active = false; heading = shown = null; clearTimeout(noSensor); }
  return { render, leave, act: { compass: start } };
})();
