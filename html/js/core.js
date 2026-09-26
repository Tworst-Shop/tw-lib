(function () {
  const { reactive } = Vue;
  const inGame = typeof GetParentResourceName === 'function';
  const RESOURCE = inGame ? GetParentResourceName() : 'tw-lib';

  const store = reactive({
    open: false, page: 'overview', range: '7d', loading: {}, updatedAt: 0, now: Date.now(),
    i18n: {}, locale: 'en', jobs: [], currency: '$', liveCount: 0,
    data: {},
    jobDetail: null,
    drawer: null,
    settingsJob: '', pending: {}, resets: {},
    toast: null, confirm: null,
  });

  function t(path, vars) {
    let node = store.i18n;
    for (const part of path.split('.')) node = node && typeof node === 'object' ? node[part] : undefined;
    let text = typeof node === 'string' ? node : path;
    if (vars) for (const k in vars) text = text.split('{' + k + '}').join(vars[k]);
    return text;
  }

  const lang = () => (store.locale === 'tr' ? 'tr-TR' : 'en-US');
  const num = n => new Intl.NumberFormat(lang()).format(Math.round(Number(n) || 0));
  const short = n => new Intl.NumberFormat(lang(), { notation: 'compact', maximumFractionDigits: 1 }).format(Number(n) || 0);
  const withCurrency = text => (store.locale === 'tr' ? text + ' ' + store.currency : store.currency + text);
  const fmt = {
    num, short,
    money: n => withCurrency(num(n)),
    moneyShort: n => withCurrency(short(n)),
    duration(sec) {
      const m = Math.round((Number(sec) || 0) / 60);
      if (m < 60) return t('units.minutes', { n: m });
      return t('units.hoursMinutes', { h: Math.floor(m / 60), m: m % 60 });
    },
    clock(sec) {
      const s = Math.max(0, Math.floor(Number(sec) || 0));
      const pad = v => String(v).padStart(2, '0');
      const h = Math.floor(s / 3600);
      return (h ? h + ':' : '') + pad(Math.floor(s / 60) % 60) + ':' + pad(s % 60);
    },
    time(value) {
      const ms = Number(value);
      const d = isFinite(ms) && ms > 0 ? new Date(ms) : new Date(String(value).replace(' ', 'T'));
      if (isNaN(d.getTime())) return String(value || '-');
      const hm = d.toLocaleTimeString(lang(), { hour: '2-digit', minute: '2-digit' });
      if (new Date().toDateString() === d.toDateString()) return hm;
      return d.toLocaleDateString(lang(), { day: 'numeric', month: 'short' }) + ' ' + hm;
    },
    day(value) {
      const d = new Date(String(value).length <= 10 ? value + 'T00:00:00' : value);
      if (isNaN(d.getTime())) return String(value);
      return d.toLocaleDateString(lang(), { day: 'numeric', month: 'short' });
    },
    ago(ms) {
      const s = Math.max(0, Math.round((store.now - ms) / 1000));
      return s < 60 ? t('units.secondsAgo', { n: s }) : t('units.minutesAgo', { n: Math.floor(s / 60) });
    },
    delta(value, prev) {
      if (prev === null || prev === undefined) return null;
      if (!prev) return value ? 100 : 0;
      return Math.round((value - prev) / prev * 100);
    },
  };

  const JOBS = {
    'tw-gardenerv2': ['Gardener', '#77ff7c'], 'tw-garbagev2': ['Garbage', '#45943e'],
    'tw-electrician': ['Electrician', '#7d8bbd'], 'tw-plumber': ['Plumber', '#77a0ff'],
    'tw-scrapyard': ['Scrapyard', '#bf9078'], 'tw-transportv2': ['Transport', '#ffe3a7'],
    'tw-diving': ['Diving', '#48bdff'], 'tw-fashion': ['Fashion', '#bdea4d'],
  };
  const job = {
    name: res => (JOBS[res] ? JOBS[res][0] : String(res || '').replace(/^tw-/, '').replace(/v\d+$/, '')),
    color(res) {
      if (JOBS[res]) return JOBS[res][1];
      let h = 0;
      for (const ch of String(res)) h = (h * 31 + ch.charCodeAt(0)) % 360;
      return 'hsl(' + h + ', 65%, 62%)';
    },
  };
  const initials = name => String(name || '?').split(/\s+/).filter(Boolean).slice(0, 2).map(w => w[0]).join('').toUpperCase();

  function post(path, body) {
    if (!inGame) return window.TwMock ? window.TwMock.handle(path, body || {}) : Promise.resolve();
    return fetch('https://' + RESOURCE + '/' + path, {
      method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(body || {}),
    }).catch(() => {});
  }

  const api = {
    load(tab, extra) {
      store.loading[tab] = true;
      return post('twlib:menu:query', Object.assign({ tab, range: store.range }, extra || {}));
    },
    receive(data) {
      if (!data || typeof data !== 'object') return;
      if (data.i18n) store.i18n = data.i18n;
      if (data.locale) store.locale = data.locale;
      if (Array.isArray(data.jobs)) store.jobs = data.jobs;
      if (data.currency) store.currency = data.currency;
      if (typeof data.liveCount === 'number') store.liveCount = data.liveCount;
      const tab = data.tab || 'overview';
      data._at = Date.now();
      store.data[tab] = data;
      store.loading[tab] = false;
      store.updatedAt = Date.now();
      if (data.toast) toast(data.toast.text, data.toast.error);
    },
    saveSettings: (resource, changes, resets) => post('twlib:menu:setting', { resource, changes, resets }),
    action: (action, body) => post('twlib:menu:action', Object.assign({ action }, body || {})),
    close: () => post('twlib:menu:close'),
  };

  let toastTimer = null;
  function toast(text, error) {
    store.toast = { text, error: !!error };
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { store.toast = null; }, 2600);
  }

  function confirm(title, text, danger) {
    return new Promise(resolve => { store.confirm = { title, text, danger: !!danger, resolve }; });
  }

  setInterval(() => { if (store.open) store.now = Date.now(); }, 1000);

  function groupLedger(rows) {
    const out = [];
    const index = {};
    for (const row of rows || []) {
      const key = row.created_at + '|' + row.identifier + '|' + row.resource;
      let e = index[key];
      if (!e) {
        e = index[key] = { key, time: row.created_at, job: row.resource, identifier: row.identifier, name: row.name,
          reason: '', account: '', money: 0, taken: 0, xp: 0, items: [] };
        out.push(e);
      }
      const amount = Number(row.amount) || 0;
      if (row.kind === 'xp') e.xp += amount;
      else if (row.kind === 'item') e.items.push({ name: row.item, count: amount, out: row.direction !== 'in' });
      else if (row.direction === 'in') { e.money += amount; e.account = row.account || e.account; }
      else { e.taken += amount; e.account = row.account || e.account; }
      if (row.kind === 'money' || !e.reason) e.reason = row.reason || e.reason;
    }
    return out;
  }

  const palette = { accent: '#58a8f5', money: '#7ddc8f', xp: '#58a8f5', ok: '#7ddc8f', bad: '#ff6b6b',
    muted: 'rgba(238,241,246,.58)', faint: 'rgba(238,241,246,.36)' };

  window.Tw = { store, t, fmt, job, palette, initials, api, toast, confirm, inGame, groupLedger };
})();
