(function () {
  let seed = 7;
  const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const int = (a, b) => Math.floor(a + rnd() * (b - a + 1));

  const JOBS = ['tw-gardenerv2', 'tw-garbagev2', 'tw-electrician', 'tw-plumber', 'tw-scrapyard', 'tw-transportv2'];
  const REGIONS = ['Vespucci Beach', 'Pillbox Hill', 'Rockford Hills', 'Richman', 'Vinewood Hills'];
  const NAMES = ['John Doe', 'Jane Roe', 'Mehmet Yılmaz', 'Ayşe Kaya', 'Carl Johnson', 'Franklin Clinton', 'Lamar Davis', 'Trevor Philips', 'Amanda Cole', 'Ali Demir'];
  const PLAYERS = NAMES.map((name, i) => ({ identifier: 'TAH' + (21004 + i * 37), name }));
  const weight = { 'tw-gardenerv2': 1, 'tw-garbagev2': .6, 'tw-electrician': .45, 'tw-plumber': .35, 'tw-scrapyard': .25, 'tw-transportv2': .15 };

  function luaToJson(src) {
    const body = src.slice(src.indexOf('{', src.indexOf('TwLib.Locales.')));
    const strings = [];
    let s = body.replace(/'((?:[^'\\]|\\.)*)'/g, (m, v) => { strings.push(v); return '@@' + (strings.length - 1) + '@@'; });
    s = s.replace(/--[^\n]*/g, '')
      .replace(/\[@@(\d+)@@\]\s*=/g, (m, i) => JSON.stringify(strings[i]) + ':')
      .replace(/([A-Za-z_]\w*)\s*=/g, '"$1":')
      .replace(/,(\s*})/g, '$1')
      .replace(/@@(\d+)@@/g, (m, i) => JSON.stringify(strings[i]));
    return JSON.parse(s);
  }

  function days(range) {
    const n = { today: 24, '7d': 7, '30d': 30, all: 60 }[range] || 7;
    if (range === 'today') return { unit: 'hour', labels: Array.from({ length: n }, (_, i) => String(i).padStart(2, '0') + ':00') };
    const out = [];
    for (let i = n - 1; i >= 0; i--) out.push(new Date(Date.now() - i * 864e5).toISOString().slice(0, 10));
    return { unit: 'day', labels: out };
  }

  function overview(range) {
    const { unit, labels } = days(range);
    const jobs = JOBS.map(job => ({
      job,
      money: labels.map(() => Math.round(int(20, 90) * 1000 * weight[job])),
      xp: labels.map(() => Math.round(int(5, 30) * 100 * weight[job])),
      sessions: labels.map(() => Math.round(int(2, 14) * weight[job])),
    }));
    const sum = key => jobs.reduce((s, j) => s + j[key].reduce((a, b) => a + b, 0), 0);
    const money = sum('money'), sessions = sum('sessions');
    return {
      kpi: { money: { value: money, prev: Math.round(money * .87) }, sessions: { value: sessions, prev: Math.round(sessions * 1.04) },
        xp: { value: sum('xp'), prev: sum('xp') }, perHour: { value: 21300, prev: 20600 } },
      working: { players: 7, lobbies: 3 },
      series: { unit, labels, jobs },
      share: jobs.map(j => ({ job: j.job, money: j.money.reduce((a, b) => a + b, 0) })).sort((a, b) => b.money - a.money),
      top: PLAYERS.slice(0, 6).map((p, i) => Object.assign({}, p, { money: 184000 - i * 21000, sessions: 30 - i * 3, perHour: 28000 - i * 1900, topJob: JOBS[i % 3] })),
      live: lobbies().slice(0, 4),
      version: '0.1.0',
    };
  }

  function lobbies() {
    return [
      { id: 1, job: 'tw-gardenerv2', region: 'Richman', seconds: 872, started: true, max: 4 },
      { id: 2, job: 'tw-gardenerv2', region: 'Vespucci Beach', seconds: 140, started: false, max: 4 },
      { id: 1, job: 'tw-garbagev2', region: 'Strawberry', seconds: 1520, started: true, max: 4 },
    ].map((l, i) => {
      const members = PLAYERS.slice(i * 2, i * 2 + 1 + (i % 3)).map(p => Object.assign({}, p));
      return Object.assign(l, { owner: members[0], members, players: members.length });
    });
  }

  function answer(req) {
    const range = req.range || '7d';
    switch (req.tab) {
      case 'overview': return overview(range);
      case 'jobs': return { list: JOBS.map(job => ({ job, money: Math.round(480000 * weight[job]), prev: Math.round(430000 * weight[job]),
        sessions: Math.round(96 * weight[job]), avgDuration: int(700, 1500), perHour: int(15, 32) * 1000, players: int(3, 20),
        spark: Array.from({ length: 12 }, () => int(20, 90)), live: job === 'tw-gardenerv2' ? 2 : job === 'tw-garbagev2' ? 1 : 0 })) };
      case 'job': {
        const { labels } = days(range === 'today' ? '7d' : range);
        const regions = REGIONS.map((region, i) => {
          const sessions = int(6, 40), avgMoney = [5000, 7500, 10000, 12500, 12500][i], avgDuration = [840, 900, 1000, 1100, 780][i];
          return { region, sessions, avgMoney, avgDuration, money: sessions * avgMoney, perHour: Math.round(avgMoney * 3600 / avgDuration) };
        });
        return { resource: req.resource, kpi: { money: { value: 482000, prev: 440000 }, sessions: { value: 96, prev: 101 },
          avgDuration: { value: 930, prev: 960 }, perHour: { value: 21300, prev: 20100 } },
          series: { labels, money: labels.map(() => int(30, 90) * 1000), sessions: labels.map(() => int(4, 16)) },
          regions, top: PLAYERS.slice(0, 5).map((p, i) => Object.assign({}, p, { money: 90000 - i * 9000, sessions: 18 - i, perHour: 26000 - i * 1500 })) };
      }
      case 'live': return { lobbies: lobbies(), quiet: ['tw-plumber'] };
      case 'players': {
        const q = String(req.search || '').toLowerCase();
        const list = PLAYERS.map((p, i) => Object.assign({}, p, { money: 184000 - i * 15000, sessions: 30 - i * 2,
          perHour: i === 2 ? 61000 : 26000 - i * 1200, topJob: JOBS[i % 4], online: i < 4, lastSeen: Date.now() - i * 3.6e6 }))
          .filter(p => !q || p.name.toLowerCase().includes(q) || p.identifier.toLowerCase().includes(q));
        return { list, avgPerHour: 22000 };
      }
      case 'player': {
        const p = PLAYERS.find(x => x.identifier === req.identifier) || PLAYERS[0];
        return { identifier: p.identifier, name: p.name, altName: 'yusuf', online: true,
          kpi: { money: 184000, xp: 42000, sessions: 31, perHour: 26500 },
          perJob: JOBS.slice(0, 3).map((job, i) => ({ job, money: 120000 - i * 45000, sessions: 18 - i * 6 })),
          recent: ledgerRows(0, p).slice(0, 18) };
      }
      case 'ledger': {
        const rows = ledgerRows(req.offset || 0).filter(r => !req.resource || r.resource === req.resource);
        return { rows, offset: req.offset || 0, hasMore: (req.offset || 0) < 100 };
      }
      case 'economy': return economy(req.resource || JOBS[0]);
    }
    return {};
  }

  function ledgerRows(offset, only) {
    const rows = [];
    for (let i = 0; i < 16; i++) {
      const p = only || PLAYERS[i % PLAYERS.length];
      const at = Date.now() - (offset + i) * 1.7e6;
      const res = JOBS[i % 3];
      rows.push({ resource: res, identifier: p.identifier, name: p.name, kind: 'money', direction: 'in', account: 'bank', amount: [5000, 7500, 12500][i % 3], reason: 'mission', created_at: at });
      rows.push({ resource: res, identifier: p.identifier, name: p.name, kind: 'xp', direction: 'in', account: '', amount: 1000, reason: 'job', created_at: at });
      if (i % 4 === 0) rows.push({ resource: res, identifier: p.identifier, name: p.name, kind: 'item', direction: 'in', item: 'sandwich', amount: 1, reason: 'mission', created_at: at });
    }
    return rows;
  }

  const saved = {};
  function economy(res) {
    if (res === 'tw-lib') {
      const row = { path: 'interaction', key: 'interaction', group: '', groupIndex: 0, order: 0, type: 'choice', default: 'drawtext',
        options: ['drawtext', 'ox-target', 'qb-target', 'auto'] };
      return { resource: res, settings: [Object.assign(row, { value: 'interaction' in saved ? saved.interaction : 'drawtext', changed: 'interaction' in saved })], lobbies: 5 };
    }
    const general = [['jobCoolDownHours', 0, 1], ['MaxPlayersInLobby', 4, 2], ['jobLevelCheck', false, 3]]
      .map(([key, def, order]) => ({ path: 'Config.' + key, key, group: '', groupIndex: 0, order, default: def, type: typeof def }));
    general.push({ path: 'Config.InteractionHandler', key: 'InteractionHandler', group: '', groupIndex: 0, order: 11, default: 'default', type: 'choice',
      options: ['default', 'drawtext', 'ox-target', 'qb-target', 'auto'] });
    const regions = [];
    REGIONS.forEach((name, i) => {
      [['regionMinimumLevel', i * 5, 4, 'regionInfo'], ['money', [5000, 7500, 10000, 12500, 12500][i], 5, 'regionAwards'], ['xp', 1000, 6, 'regionAwards'],
        ['onlineJobExtraAwards', 2, 7, 'regionAwards'], ['bonusExtraMoney', 0, 8, 'regionAwards'], ['bonusExtraXP', 0, 9, 'regionAwards']]
        .forEach(([key, def, order, parent]) => regions.push({ path: 'Config.Job.regionData.' + (i + 1) + '.' + parent + '.' + key, key, group: name,
          groupKey: 'regionData', groupIndex: i + 1, order, default: def, type: 'number' }));
    });
    const settings = general.concat(regions).map(r => Object.assign(r, { value: r.path in saved ? saved[r.path] : r.default, changed: r.path in saved }));
    return { resource: res, settings, lobbies: 2, regionStats: { 1: 21400, 2: 30000, 3: 36000, 4: 40900, 5: 57700 } };
  }

  function reply(data) { setTimeout(() => Tw.api.receive(Object.assign({ jobs: JOBS, currency: '$', liveCount: 3 }, data)), 220); }

  window.TwMock = {
    handle(path, body) {
      if (path === 'twlib:menu:query') reply(Object.assign({ tab: body.tab }, answer(body)));
      if (path === 'twlib:menu:setting') {
        (body.changes || []).forEach(c => { saved[c.path] = c.value; });
        (body.resets || []).forEach(p => { delete saved[p]; });
        reply(Object.assign({ tab: 'economy', saved: (body.changes || []).length, errors: [], restartNeeded: true }, economy(body.resource)));
      }
      if (path === 'twlib:menu:action') setTimeout(() => Tw.toast(body.action + ' → ' + (body.resource || '')), 150);
      if (path === 'twlib:menu:close') setTimeout(() => { Tw.store.open = true; }, 600);
      return Promise.resolve();
    },
    async boot() {
      const params = new URLSearchParams(location.search);
      const locale = params.get('lang') || 'en';
      let i18n = {};
      try { i18n = luaToJson(await (await fetch('../locales/' + locale + '.lua')).text()); }
      catch (e) { console.warn('preview: locales not reachable, serve the resource folder as root'); }
      await loadMenu();
      Tw.store.open = true;
      Tw.api.receive(Object.assign({ tab: 'overview', i18n, locale, jobs: JOBS, currency: '$', liveCount: 3 }, overview('7d')));
      if (params.get('page')) { Tw.store.page = params.get('page'); }
    },
  };
})();
