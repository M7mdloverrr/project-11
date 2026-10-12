(function () {
  "use strict";

  var state = {
    surahs: [],
    current: null,
    from: 1,
    to: 7,
    selectedVerses: {}
  };

  var els = {
    surahList: document.getElementById("surah-list"),
    surahSelect: document.getElementById("surah-select"),
    fromSelect: document.getElementById("from-ayah"),
    toSelect: document.getElementById("to-ayah"),
    readBtn: document.getElementById("read-btn"),
    fullBtn: document.getElementById("full-surah-btn"),
    search: document.getElementById("surah-search"),
    verses: document.getElementById("verses"),
    bismillah: document.getElementById("bismillah"),
    surahHeader: document.getElementById("surah-header"),
    surahName: document.getElementById("surah-name"),
    surahMeta: document.getElementById("surah-meta"),
    prevBtn: document.getElementById("prev-surah"),
    nextBtn: document.getElementById("next-surah")
  };

  function pad3(n) {
    return ("00" + n).slice(-3);
  }

  var BISMILLAH = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";

  function normalizeArabic(s) {
    return s
      .replace(/\uFEFF/g, "")
      .replace(/[\u064B-\u065F\u0670\u0640\u06D6-\u06ED]/g, "");
  }

  function stripBismillah(surahNumber, ayahNumber, ayahText) {
    if (ayahText.charCodeAt(0) === 0xfeff) {
      ayahText = ayahText.slice(1);
    }
    if (surahNumber !== 1 && surahNumber !== 9 && ayahNumber === 1) {
      var norm = normalizeArabic(ayahText);
      var prefixNorm = normalizeArabic(BISMILLAH);
      if (norm.indexOf(prefixNorm) === 0) {
        var acc = "";
        var count = 0;
        for (var i = 0; i < ayahText.length && acc.length < prefixNorm.length; i++) {
          acc += normalizeArabic(ayahText.charAt(i));
          count = i + 1;
        }
        ayahText = ayahText.slice(count).trim();
      }
    }
    return ayahText;
  }

  function loadJSON(url) {
    return fetch(url).then(function (r) {
      if (!r.ok) throw new Error("تعذر تحميل " + url + " (" + r.status + ")");
      return r.json();
    });
  }

  var quranCache = null;

  function loadQuran() {
    if (quranCache) return Promise.resolve(quranCache);
    return loadJSON("data/quran-uthmani.json").then(function (res) {
      quranCache = res;
      return res;
    });
  }

  function init() {
    loadJSON("data/surahs-meta.json")
      .then(function (res) {
        state.surahs = res.data;
        buildIndex();
        buildSelectors();
        bindEvents();
        var initial = state.surahs[0];
        selectSurah(initial.number);
        readSelection();
      })
      .catch(function (err) {
        els.verses.innerHTML = '<p class="placeholder">حدث خطأ أثناء تحميل بيانات القرآن: ' + err.message + "</p>";
      });
  }

  function buildIndex() {
    els.surahList.innerHTML = "";
    state.surahs.forEach(function (s) {
      var li = document.createElement("li");
      var btn = document.createElement("button");
      btn.className = "surah-link";
      btn.dataset.number = s.number;
      btn.dataset.name = normalizeArabic(
        s.name + " " + s.englishName + " " + s.englishNameTranslation
      ).toLowerCase();
      btn.type = "button";

      var num = document.createElement("span");
      num.className = "surah-num";
      num.textContent = pad3(s.number);

      var name = document.createElement("span");
      name.className = "surah-name";
      name.textContent = s.name;

      var count = document.createElement("span");
      count.className = "surah-count";
      count.textContent = s.numberOfAyahs + " آية";

      btn.appendChild(num);
      btn.appendChild(name);
      btn.appendChild(count);
      btn.addEventListener("click", function () {
        selectSurah(s.number);
      });
      li.appendChild(btn);
      els.surahList.appendChild(li);
    });
  }

  function fillAyahSelects(count) {
    var i;
    els.fromSelect.innerHTML = "";
    els.toSelect.innerHTML = "";
    for (i = 1; i <= count; i++) {
      els.fromSelect.add(new Option(String(i), String(i)));
      els.toSelect.add(new Option(String(i), String(i)));
    }
    els.fromSelect.value = "1";
    els.toSelect.value = String(count);
  }

  function buildSelectors() {
    state.surahs.forEach(function (s) {
      var label = pad3(s.number) + " — " + s.name;
      els.surahSelect.add(new Option(label, String(s.number)));
    });
  }

  function markActiveIndex(number) {
    var links = els.surahList.querySelectorAll(".surah-link");
    links.forEach(function (link) {
      link.classList.toggle("active", Number(link.dataset.number) === number);
    });
    var active = els.surahList.querySelector(".surah-link.active");
    if (active && active.scrollIntoView) {
      active.scrollIntoView({ block: "nearest" });
    }
  }

  function selectSurah(number, scroll) {
    var surah = state.surahs.find(function (s) { return s.number === number; });
    if (!surah) return;
    state.current = surah;
    state.selectedVerses = {};
    els.surahSelect.value = String(number);
    fillAyahSelects(surah.numberOfAyahs);
    state.from = 1;
    state.to = surah.numberOfAyahs;
    markActiveIndex(number);
    renderSurahHeader();
    if (scroll) {
      document.querySelector(".reading-panel").scrollIntoView({ behavior: "smooth" });
    }
  }

  function renderSurahHeader() {
    var s = state.current;
    if (!s) return;
    els.surahName.textContent = s.name;
    els.surahMeta.textContent =
      "عدد آياتها " + s.numberOfAyahs + " — " + (s.revelationType === "Meccan" ? "مكية" : "مدنية");
    els.surahHeader.classList.remove("hidden");
  }

  function renderVerses(surahNumber, from, to) {
    els.verses.innerHTML = '<p class="placeholder">جارٍ تحميل الآيات…</p>';
    loadQuran()
      .then(function (res) {
        var surah = res.data.surahs.find(function (s) { return s.number === surahNumber; });
        if (!surah) throw new Error("لم يتم العثور على السورة");
        els.verses.innerHTML = "";
        showBismillah(surah.number, from);
        surah.ayahs
          .filter(function (a) { return a.numberInSurah >= from && a.numberInSurah <= to; })
          .forEach(function (ayah) {
            var span = document.createElement("span");
            span.className = "verse";
            if (state.selectedVerses[ayah.numberInSurah]) span.classList.add("selected");
            span.dataset.ayah = String(ayah.numberInSurah);

            var text = document.createElement("span");
            text.textContent = stripBismillah(surah.number, ayah.numberInSurah, ayah.text);

            var num = document.createElement("span");
            num.className = "verse-num";
            num.textContent = " ﴿" + ayah.numberInSurah + "﴾ ";

            span.appendChild(text);
            span.appendChild(num);
            if (ayah.sajda) {
              var mark = document.createElement("span");
              mark.className = "sajda-mark";
              mark.title = "موضع سجدة";
              mark.textContent = "۩";
              span.appendChild(mark);
            }
            span.addEventListener("click", function () {
              span.classList.toggle("selected");
              state.selectedVerses[ayah.numberInSurah] = span.classList.contains("selected");
            });
            els.verses.appendChild(span);
            els.verses.appendChild(document.createTextNode(" "));
          });
      })
      .catch(function (err) {
        els.verses.innerHTML = '<p class="placeholder">تعذر تحميل الآيات: ' + err.message + "</p>";
      });
  }

  function showBismillah(surahNumber, from) {
    if (surahNumber !== 1 && surahNumber !== 9 && from === 1) {
      els.bismillah.classList.remove("hidden");
    } else {
      els.bismillah.classList.add("hidden");
    }
  }

  function bindEvents() {
    els.surahSelect.addEventListener("change", function () {
      selectSurah(Number(els.surahSelect.value));
      readSelection();
    });

    els.fromSelect.addEventListener("change", function () {
      var from = Number(els.fromSelect.value);
      var to = Number(els.toSelect.value);
      if (from > to) {
        els.toSelect.value = String(from);
        to = from;
      }
    });

    els.readBtn.addEventListener("click", readSelection);

    els.fullBtn.addEventListener("click", function () {
      if (!state.current) return;
      els.fromSelect.value = "1";
      els.toSelect.value = String(state.current.numberOfAyahs);
      readSelection();
    });

    els.search.addEventListener("input", function () {
      var q = normalizeArabic(els.search.value.trim()).toLowerCase();
      var links = els.surahList.querySelectorAll(".surah-link");
      links.forEach(function (link) {
        var match = !q || link.dataset.name.indexOf(q) !== -1;
        link.parentElement.style.display = match ? "" : "none";
      });
    });

    els.prevBtn.addEventListener("click", function () {
      if (state.current && state.current.number > 1) {
        selectSurah(state.current.number - 1, true);
        readSelection();
      }
    });

    els.nextBtn.addEventListener("click", function () {
      if (state.current && state.current.number < 114) {
        selectSurah(state.current.number + 1, true);
        readSelection();
      }
    });
  }

  function readSelection() {
    if (!state.current) return;
    var from = Math.max(1, Number(els.fromSelect.value) || 1);
    var to = Math.min(state.current.numberOfAyahs, Number(els.toSelect.value) || 1);
    if (from > to) { var t = from; from = to; to = t; }
    state.from = from;
    state.to = to;
    renderVerses(state.current.number, from, to);
    document.querySelector(".reading-panel").scrollIntoView({ behavior: "smooth" });
  }

  document.addEventListener("DOMContentLoaded", init);
})();
