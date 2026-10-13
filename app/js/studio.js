'use strict';
const BACKGROUNDS = [
  { id: 'waterfall', ar: 'شلال', credit: 'Llywelyn2000, CC BY-SA 4.0' }, { id: 'forest', ar: 'غابة', credit: 'Queen Asali, CC BY-SA 4.0' },
  { id: 'ocean', ar: 'بحر', credit: 'Nature video, HD - 4K, CC BY 3.0' }, { id: 'mountains', ar: 'جبال', credit: 'Pastelitodepapa, CC0' },
  { id: 'rain', ar: 'مطر', credit: 'Shishirdasika, CC BY-SA 4.0' }, { id: 'sunset', ar: 'غروب', credit: 'Ian Furst, CC BY-SA 4.0' }];
const ST_FONTS = [['QuranFont', 'أميري قرآن'], ['"Noto Naskh Arabic","Geeza Pro","Traditional Arabic",serif', 'نسخ']];
const ST_COLORS = ['#FFFFFF', '#F2D48A', '#BDEFD9', '#111111'];
const ASPECTS = [['9:16', 9, 16], ['16:9', 16, 9], ['1:1', 1, 1]];

const Studio = (() => {
  const S = { s: 1, from: 1, to: 7, reciter: 'maher', bg: 0, custom: null, font: 0, size: 1, color: '#FFFFFF', pos: 1, shadow: true, dim: 0.35, aspect: 0, hd: false };
  let job = null, actx = null, result = null, idleVid = null; const bgUrls = {}, thumbs = {};
  const getCtx = () => { if (!actx || actx.state === 'closed') actx = new (window.AudioContext || window.webkitAudioContext)(); return actx; };
  const count = () => QD.surahs[S.s - 1].ayahs.length;
  function dims(hd = S.hd) { const [, w, h] = ASPECTS[S.aspect], sh = hd ? 1080 : 720, k = sh / Math.min(w, h); return [Math.round(w * k / 2) * 2, Math.round(h * k / 2) * 2]; }
  const pdims = () => { const [w, h] = dims(false); return [w / 2, h / 2]; };
  async function bgSrc() {
    if (S.custom) return S.custom;
    const id = BACKGROUNDS[S.bg].id;
    if (!bgUrls[id]) { const r = await fetch(`assets/bg/${id}.mp4`).catch(() => null); if (!r || !r.ok) throw new Error('bg'); bgUrls[id] = URL.createObjectURL(await r.blob()); }
    return bgUrls[id];
  }
  async function makeVideo(src) {
    const v = document.createElement('video'); v.muted = true; v.loop = true; v.playsInline = true; v.setAttribute('playsinline', ''); v.src = src;
    await new Promise((res, rej) => { v.onerror = () => rej(new Error('bg')); v.play().then(res, rej); });
    return v;
  }
  const fontStr = px => `${px}px ${ST_FONTS[S.font][0]}`;
  function wrap(g, text, maxW) {
    const words = text.split(' '), lines = []; let cur = '';
    for (const w of words) { const t = cur ? cur + ' ' + w : w; if (g.measureText(t).width > maxW && cur) { lines.push(cur); cur = w; } else cur = t; }
    if (cur) lines.push(cur); return lines;
  }
  function drawBg(g, W, H, src) {
    if (src) { const vw = src.videoWidth || src.naturalWidth || 16, vh = src.videoHeight || src.naturalHeight || 9, sc = Math.max(W / vw, H / vh); g.drawImage(src, (W - vw * sc) / 2, (H - vh * sc) / 2, vw * sc, vh * sc); }
    else { g.fillStyle = '#063D2C'; g.fillRect(0, 0, W, H); }
    g.fillStyle = `rgba(0,0,0,${S.dim})`; g.fillRect(0, 0, W, H);
  }
  function drawVerse(g, W, H, s, a, fade) {
    const text = ay(s, a)[0] + '\u00A0\u06DD' + AR(a);
    let px = Math.min(W, H) * 0.064 * S.size, lines; const maxW = W * 0.84, maxH = H * (W > H ? 0.6 : 0.56);
    g.direction = 'rtl'; g.textAlign = 'center'; g.textBaseline = 'middle';
    for (;;) { g.font = fontStr(px); lines = wrap(g, text, maxW); if (lines.length * px * 1.8 <= maxH || px < 12) break; px *= 0.92; }
    const lh = px * 1.8, cap = Math.max(10, px * 0.4), block = lines.length * lh + cap * 2.2, m = H * 0.06;
    let cy = S.pos === 0 ? m + block / 2 + H * 0.06 : S.pos === 2 ? H - m - block / 2 - H * 0.06 : H / 2;
    cy = Math.min(H - m - block / 2, Math.max(m + block / 2, cy));
    const e = 1 - Math.pow(1 - Math.max(0, Math.min(1, fade)), 3);
    g.save(); g.globalAlpha = e; g.fillStyle = S.color;
    if (S.shadow) { g.shadowColor = S.color === '#111111' ? 'rgba(255,255,255,.75)' : 'rgba(0,0,0,.85)'; g.shadowBlur = px * 0.35; g.shadowOffsetY = px * 0.05; }
    let y = cy - block / 2 + lh / 2 + (1 - e) * px * 0.4;
    g.font = fontStr(px); for (const l of lines) { g.fillText(l, W / 2, y); y += lh; }
    g.font = `${cap}px -apple-system, "Segoe UI", Roboto, sans-serif`; g.globalAlpha = e * 0.85;
    g.fillText(`${sname(s)} • الآية ${AR(a)} • ${rec(S.reciter).ar}`, W / 2, y - lh / 2 + cap * 1.4);
    g.restore();
  }
  function thumb(i) { if (!thumbs[i]) { const im = new Image(); im.src = `assets/bg/${BACKGROUNDS[i].id}.jpg`; im.onload = () => { if (!job) drawIdle(); }; thumbs[i] = im; } return thumbs[i]; }
  function drawIdle() {
    const c = $('#stc'); if (!c || job) return;
    const [W, H] = pdims(); c.width = W; c.height = H; const g = c.getContext('2d');
    const src = S.custom ? idleVid : thumb(S.bg);
    drawBg(g, W, H, src && (src.complete || src.readyState >= 2) ? src : null); drawVerse(g, W, H, S.s, S.from, 1);
  }
  const pickMime = () => typeof MediaRecorder === 'undefined' ? '' : ['video/mp4;codecs=avc1.640028,mp4a.40.2', 'video/mp4;codecs=avc1.4d0028,mp4a.40.2', 'video/mp4;codecs=avc1,mp4a', 'video/mp4', 'video/webm;codecs=vp9,opus', 'video/webm;codecs=vp8,opus', 'video/webm'].find(m => MediaRecorder.isTypeSupported(m)) || '';
  const errMsg = e => e.message === 'bg' ? 'تعذر تحميل الخلفية' : e.message === 'rec' ? 'هذا المتصفح لا يدعم تسجيل الفيديو. استخدم سفاري أو كروم حديثاً' : e.message === 'hidden' ? 'توقف التصدير لأن التطبيق خرج من الشاشة. أعد المحاولة وأبقِ الشاشة مفتوحة' : audioErr(e);

  async function run(kind) {
    const ctx = getCtx(); ctx.resume();
    stopJob(); const my = { kind, cancelled: false, srcs: [], p: 0, msg: 'جارٍ تجهيز التلاوة…' }; job = my; if (kind === 'export') { result = null; showResult(); } ui();
    try {
      const clips = []; for (let a = S.from; a <= S.to; a++) clips.push({ s: S.s, a });
      let done = 0, i = 0;
      await Promise.all([0, 1, 2, 3].map(async () => {
        while (i < clips.length && !my.cancelled) {
          const c = clips[i++], blob = await audioBlob(S.reciter, c.s, c.a);
          c.dur = (await ctx.decodeAudioData(await blob.arrayBuffer())).duration;
          done++; prog(my, done / clips.length * 0.1, `تجهيز التلاوة ${AR(Math.round(done / clips.length * 100))}٪`);
        }
      }));
      if (my.cancelled) return;
      let t = 0; for (const c of clips) { c.start = t; t += c.dur; } const total = t;
      const video = my.video = await makeVideo(await bgSrc()); if (my.cancelled) { video.pause(); return; }
      await document.fonts?.load?.(fontStr(40)).catch(() => {});
      const [W, H] = kind === 'export' ? dims() : pdims();
      let canvas = $('#stc');
      if (kind === 'export') { canvas = document.createElement('canvas'); canvas.dir = 'rtl'; canvas.style.cssText = 'position:fixed;left:-99999px;top:0;width:10px;height:10px'; document.body.append(canvas); my.canvas = canvas; }
      canvas.width = W; canvas.height = H; const g = canvas.getContext('2d');
      let out = ctx.destination, chunks = [], mime = '';
      if (kind === 'export') {
        mime = pickMime(); if (!mime || !canvas.captureStream) throw new Error('rec');
        const dest = ctx.createMediaStreamDestination(); out = dest;
        const r = my.rec = new MediaRecorder(new MediaStream([...canvas.captureStream(30).getVideoTracks(), ...dest.stream.getAudioTracks()]), { mimeType: mime, videoBitsPerSecond: S.hd ? 10e6 : 6e6, audioBitsPerSecond: 192000 });
        r.ondataavailable = e => { if (e.data.size) chunks.push(e.data); };
      }
      let next = 0, busy = false, t0 = 0;
      const sched = async lead => {
        if (busy) return; busy = true;
        try {
          while (next < clips.length && !my.cancelled && clips[next].start - (ctx.currentTime - t0) < lead) {
            const c = clips[next++], buf = c.buf || await ctx.decodeAudioData(await (await audioBlob(S.reciter, c.s, c.a)).arrayBuffer()); c.buf = null;
            if (my.cancelled) return;
            const src = ctx.createBufferSource(); src.buffer = buf; src.connect(out); src.start(t0 + c.start); my.srcs.push(src);
            src.onended = () => { my.srcs = my.srcs.filter(x => x !== src); };
          }
        } catch (e) { fail(my, e); } finally { busy = false; }
      };
      drawBg(g, W, H, video); drawVerse(g, W, H, clips[0].s, clips[0].a, 0);
      if (my.rec) my.rec.start(1000);
      clips[0].buf = await ctx.decodeAudioData(await (await audioBlob(S.reciter, clips[0].s, clips[0].a)).arrayBuffer());
      if (my.cancelled) return;
      video.currentTime = 0; t0 = ctx.currentTime + 0.3; await sched(12);
      const tick = () => {
        if (my.cancelled) return;
        const tl = ctx.currentTime - t0; sched(12);
        let k = 0; while (k < clips.length - 1 && clips[k + 1].start <= tl) k++;
        drawBg(g, W, H, video); drawVerse(g, W, H, clips[k].s, clips[k].a, (tl - clips[k].start) / 0.45);
        const pct = Math.max(0, Math.min(1, tl / total));
        prog(my, kind === 'export' ? 0.1 + pct * 0.9 : pct, kind === 'export' ? `جارٍ تسجيل الفيديو ${AR(Math.round(pct * 100))}٪ — أبقِ الشاشة مفتوحة` : `معاينة: الآية ${AR(clips[k].a)}`);
        if (tl >= total + 0.4) { finish(my, chunks, mime); return; }
        my.raf = requestAnimationFrame(tick);
      };
      my.raf = requestAnimationFrame(tick);
    } catch (e) { fail(my, e); }
  }
  function fail(my, e) { if (job !== my || my.cancelled) return; stopJob(); toast(errMsg(e), 'إعادة المحاولة', () => run(my.kind)); }
  function finish(my, chunks, mime) {
    if (my.kind !== 'export') { stopJob(); return; }
    const r = my.rec;
    r.onstop = () => {
      const type = mime.split(';')[0], ext = type.includes('mp4') ? 'mp4' : 'webm', blob = new Blob(chunks, { type });
      const name = `Quran_${S.s}_${S.from}-${S.to}_${Date.now()}.${ext}`;
      result = { blob, url: URL.createObjectURL(blob), name, type, ext };
      my.cancelled = true; cleanup(my); job = null; ui(); showResult(); drawIdle();
    };
    my.cancelled = true; cancelAnimationFrame(my.raf); r.stop();
  }
  function cleanup(my) {
    cancelAnimationFrame(my.raf); my.srcs.forEach(s => { try { s.stop(); } catch {} }); my.srcs = [];
    my.video?.pause(); my.canvas?.remove();
  }
  function stopJob() {
    const my = job; if (!my) return; my.cancelled = true;
    if (my.rec && my.rec.state !== 'inactive') { my.rec.onstop = null; my.rec.stop(); }
    cleanup(my); job = null; ui(); drawIdle();
  }
  function prog(my, p, msg) { if (job !== my) return; my.p = p; my.msg = msg; const b = $('#stprog'); if (b) { b.style.width = p * 100 + '%'; $('#stmsg').textContent = msg; } }
  function ui() {
    const el = $('#stjob'); if (!el) return;
    $('#stpad')?.classList.toggle('busy', job?.kind === 'export');
    $('#pvb').innerHTML = job?.kind === 'preview' ? `${ic('stop')} إيقاف` : `${ic('play')} معاينة`;
    $('#exb').toggleAttribute('disabled', job?.kind === 'export');
    el.innerHTML = job ? `<div class="card"><small id="stmsg">${job.msg}</small><div class="prog"><i id="stprog" style="width:${job.p * 100}%"></i></div>${job.kind === 'export' ? `<button class="btn ghost sm" data-act="stCancel">إلغاء التصدير</button>` : ''}</div>` : '';
  }
  function showResult() {
    const el = $('#stres'); if (!el) return;
    el.innerHTML = result ? `<div class="card"><p>${ic('check')} الفيديو جاهز (${result.ext.toUpperCase()} • ${AR((result.blob.size / 1048576).toFixed(1))} م.ب)</p><video class="res" src="${result.url}" controls playsinline></video>
      <div class="btns"><button class="btn" data-act="stShare">${ic('share')} حفظ / مشاركة</button><a class="btn ghost" href="${result.url}" download="${result.name}">${ic('download')} تنزيل</a></div>
      <small>على الآيفون: اضغط «حفظ / مشاركة» ثم «حفظ الفيديو» لحفظه في الصور.</small></div>` : '';
  }
  function render(v) {
    route = 'studio';
    const n = count();
    v.innerHTML = `${header('استوديو الفيديو')}
    <div class="pad" id="stpad">
      <div class="stage"><canvas id="stc" dir="rtl"></canvas></div>
      <div class="btns"><button class="btn" id="exb" data-act="stExport">${ic('movie')} تصدير الفيديو</button><button class="btn ghost" id="pvb" data-act="stPreview"></button></div>
      <div id="stjob"></div><div id="stres"></div>
      <section class="card lock"><h3>الآيات</h3>
        <select id="sts">${QD.surahs.map(s => `<option value="${s.n}" ${s.n === S.s ? 'selected' : ''}>${AR(s.n)}. ${s.name}</option>`).join('')}</select>
        <small id="strl"></small>
        <div class="rowx"><span>من الآية</span><div class="steps"><button class="ib" data-act="stStep" data-k="from" data-d="-1">${ic('minus')}</button><b id="stf"></b><button class="ib" data-act="stStep" data-k="from" data-d="1">${ic('plus')}</button></div></div>
        <input type="range" id="strf" min="1" max="${n}" value="${S.from}">
        <div class="rowx"><span>إلى الآية</span><div class="steps"><button class="ib" data-act="stStep" data-k="to" data-d="-1">${ic('minus')}</button><b id="stt"></b><button class="ib" data-act="stStep" data-k="to" data-d="1">${ic('plus')}</button></div></div>
        <input type="range" id="strt" min="1" max="${n}" value="${S.to}">
        <div class="chips"><button data-act="stOne">آية واحدة</button><button data-act="stAll">السورة كاملة</button></div></section>
      <section class="card lock"><h3>القارئ</h3><div class="chips">${RECITERS.map(r => `<button data-st="reciter" data-v="${r.id}">${r.ar}</button>`).join('')}</div></section>
      <section class="card lock"><h3>الخلفية</h3><div class="thumbs">${BACKGROUNDS.map((b, i) => `<button class="thumb" data-st="bg" data-v="${i}"><img src="assets/bg/${b.id}.jpg" alt="" loading="lazy">${b.ar}</button>`).join('')}
        <label class="thumb" id="stimp"><span class="imp">${ic('upload')}</span>من جهازك<input type="file" accept="video/*" id="stfile" hidden></label></div></section>
      <section class="card lock"><h3>النص</h3>
        <div class="chips">${ST_FONTS.map((f, i) => `<button data-st="font" data-v="${i}">${f[1]}</button>`).join('')}</div>
        <small>حجم الخط</small><input type="range" id="stsz" min="0.6" max="1.6" step="0.05" value="${S.size}">
        <small>اللون</small><div class="chips">${ST_COLORS.map(c => `<button class="dot" data-st="color" data-v="${c}" style="background:${c}" aria-label="${c}"></button>`).join('')}</div>
        <small>الموضع</small><div class="chips">${['أعلى', 'وسط', 'أسفل'].map((l, i) => `<button data-st="pos" data-v="${i}">${l}</button>`).join('')}</div>
        <div class="rowx"><span>ظل للنص</span><label class="sw"><input type="checkbox" id="stsh" ${S.shadow ? 'checked' : ''}><span></span></label></div>
        <small>تعتيم الخلفية</small><input type="range" id="stdim" min="0" max="0.8" step="0.05" value="${S.dim}"></section>
      <section class="card lock"><h3>الإخراج</h3>
        <div class="chips">${ASPECTS.map((a, i) => `<button data-st="aspect" data-v="${i}">${a[0]}</button>`).join('')}</div>
        <div class="chips"><button data-st="hd" data-v="0">720p</button><button data-st="hd" data-v="1">1080p</button></div><small id="stest"></small></section>
      <p class="credits">مصادر الخلفيات (Wikimedia Commons): ${BACKGROUNDS.map(b => `${b.ar}: ${b.credit}`).join(' • ')}. التلاوات: EveryAyah.com.</p>
    </div>`;
    const on = (id, ev, f) => $(id).addEventListener(ev, f);
    on('#sts', 'change', e => { S.s = +e.target.value; S.from = 1; S.to = count(); stopPreview(); render($('#view')); });
    on('#strf', 'input', e => { S.from = +e.target.value; if (S.to < S.from) S.to = S.from; stopPreview(); refresh(); });
    on('#strt', 'input', e => { S.to = +e.target.value; if (S.from > S.to) S.from = S.to; stopPreview(); refresh(); });
    on('#stsz', 'input', e => { S.size = +e.target.value; drawIdle(); });
    on('#stdim', 'input', e => { S.dim = +e.target.value; drawIdle(); });
    on('#stsh', 'change', e => { S.shadow = e.target.checked; drawIdle(); });
    on('#stfile', 'change', e => {
      const f = e.target.files[0]; if (!f) return;
      if (S.custom) URL.revokeObjectURL(S.custom); S.custom = URL.createObjectURL(f); stopPreview();
      makeVideo(S.custom).then(v => { v.pause(); idleVid = v; refresh(); }).catch(() => { toast('تعذر فتح هذا الفيديو. جرّب ملفاً بصيغة MP4 أو MOV'); S.custom = null; refresh(); });
      refresh();
    });
    $('#stpad').addEventListener('click', e => {
      const b = e.target.closest('[data-st]'); if (!b || job?.kind === 'export') return;
      const k = b.dataset.st, v = b.dataset.v;
      S[k] = k === 'reciter' || k === 'color' ? v : k === 'hd' ? v === '1' : +v;
      if (k === 'bg') { S.custom = null; idleVid = null; }
      if (['reciter', 'bg'].includes(k)) stopPreview();
      refresh();
    });
    refresh(); ui(); showResult(); document.fonts?.load?.(fontStr(40)).then(drawIdle, drawIdle);
  }
  function refresh() {
    const n = count();
    $('#stf').textContent = AR(S.from); $('#stt').textContent = AR(S.to); $('#strf').value = S.from; $('#strt').value = S.to;
    $('#strl').textContent = `من الآية ${AR(S.from)} إلى الآية ${AR(S.to)} (${AR(S.to - S.from + 1)} آية من ${AR(n)})`;
    $$('#stpad [data-st]').forEach(b => { const k = b.dataset.st, v = b.dataset.v; b.classList.toggle('on', k === 'bg' ? !S.custom && +v === S.bg : k === 'hd' ? (v === '1') === S.hd : String(S[k]) === v); });
    $('#stimp').classList.toggle('on', !!S.custom);
    const [W, H] = dims();
    $('#stest').textContent = `${W}×${H} — التصدير يتم أثناء تشغيل التلاوة، فيستغرق تقريباً مدة الفيديو نفسها. أبقِ الشاشة مفتوحة.`;
    drawIdle();
  }
  function stopPreview() { if (job?.kind === 'preview') stopJob(); }
  document.addEventListener('visibilitychange', () => { if (document.hidden && job) { const k = job.kind; stopJob(); if (k === 'export') toast(errMsg(new Error('hidden'))); } });
  const act = {
    stPreview() { if (job?.kind === 'preview') stopJob(); else if (!job) run('preview'); },
    stExport() { if (!job || job.kind === 'preview') run('export'); },
    stCancel() { stopJob(); toast('تم إلغاء التصدير'); },
    stStep(el) { if (job?.kind === 'export') return; const k = el.dataset.k, n = count(); S[k] = Math.max(1, Math.min(n, S[k] + +el.dataset.d)); if (k === 'from' && S.to < S.from) S.to = S.from; if (k === 'to' && S.from > S.to) S.from = S.to; stopPreview(); refresh(); },
    stOne() { if (job?.kind === 'export') return; S.to = S.from; stopPreview(); refresh(); },
    stAll() { if (job?.kind === 'export') return; S.from = 1; S.to = count(); stopPreview(); refresh(); },
    async stShare() {
      if (!result) return;
      const f = new File([result.blob], result.name, { type: result.type });
      if (navigator.canShare?.({ files: [f] })) { try { await navigator.share({ files: [f], title: 'فيديو تلاوة' }); } catch (e) { if (e.name !== 'AbortError') toast('تعذرت المشاركة'); } }
      else { const a = document.createElement('a'); a.href = result.url; a.download = result.name; document.body.append(a); a.click(); a.remove(); }
    },
  };
  return { render, leave: stopJob, act, S, _job: () => job, _result: () => result };
})();
