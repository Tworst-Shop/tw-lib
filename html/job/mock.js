(function () {
  const send = (action, payload) => window.postMessage({ action, payload }, '*');
  const avatar = i => 'https://i.pravatar.cc/80?img=' + (10 + i);

  function parseLocales(text) {
    const out = {};
    for (const line of text.split('\n')) {
      const a = line.indexOf("['");
      const b = a < 0 ? -1 : line.indexOf("']", a);
      const eq = b < 0 ? -1 : line.indexOf('=', b);
      if (eq < 0) continue;
      const rest = line.slice(eq + 1).trim();
      const q = rest[0];
      const end = rest.lastIndexOf(q);
      if ((q === '"' || q === "'") && end > 0) out[line.slice(a + 2, b)] = rest.slice(1, end);
    }
    return out;
  }

  const players = [1, 2, 3].map(i => ({ playerName: ['John Doe', 'Jane Roe', 'Ali Demir'][i - 1], playerIdentifier: 'ID' + i,
    playerImage: avatar(i), playerLevel: 3 * i, playerOwner: i === 1, source: i }));
  const tasks = [
    { jobName: 'task1', jobLabel: 'Mow the lawn', madeAmount: 12, jobCount: 25, finish: false, invisible: false, img: '' },
    { jobName: 'task2', jobLabel: 'Trim the bushes', madeAmount: 10, jobCount: 10, finish: true, invisible: false, img: '' },
    { jobName: 'task3', jobLabel: 'Cut the branches', madeAmount: 0, jobCount: 2, finish: false, invisible: false, img: '' },
    { jobName: 'task4', jobLabel: 'Plant flowers', madeAmount: 3, jobCount: 8, finish: false, invisible: false, img: '' },
  ];
  const regionCount = Number(new URLSearchParams(location.search).get('regions')) || 5;
  const regions = [1, 2, 3, 4, 5].slice(0, regionCount).map(i => ({
    regionID: i,
    regionInfo: { regionName: ['Vespucci Beach', 'Pillbox Hill', 'Rockford Hills', 'Richman', 'Vinewood Hills'][i - 1],
      regionJobTask: 'Lawn, bushes, branches and flowers', regionImage: 'region.png', regionMinimumLevel: (i - 1) * 5 },
    regionAwards: { money: 2500 * (i + 1), xp: 1000, onlineJobExtraAwards: 2, bonusExtraMoney: 0, bonusExtraXP: 0 },
  }));

  async function boot() {
    let locales = {};
    try { locales = parseLocales(await (await fetch('../defaults/locales/en.lua')).text()); } catch (e) {   }
    send('STATE', {
      serverName: 'TWORST', serverMoneyType: '$', locales, regionData: regions,
      dailyMission: [{ name: 'd1', header: 'Daily 1', label: 'Finish 3 jobs', count: 3, xp: 500, money: 1000 },
        { name: 'd2', header: 'Daily 2', label: 'Trim 50 bushes', count: 50, xp: 800, money: 2000 }],
      tutorialList: [
        { id: 1, title: 'How to start a job', description: 'Pick a region, invite your crew and press <b>Start</b>. The region sets the payout and the task list.', name: '' },
        { id: 2, title: 'Working with a crew', description: 'Every member earns their own score; the payout is split by what each of them did.', name: '' },
        { id: 3, title: 'The vehicle', description: 'The keys are handed to the crew leader. Park it back at the depot to finish the job.', name: '' },
        { id: 4, title: 'Levels and daily missions', description: 'Tasks give XP. A higher level unlocks the regions that pay more.', name: '' },
      ],
      languageTitle: [{ value: 'en', label: 'English' }, { value: 'tr', label: 'Türkçe' }],
      defaultLogo: avatar(1),
    });
    send('OPEN_MENU', { playerIdentifier: 'ID1', playerImage: avatar(1), playerLevel: 7, playerXp: 1400, playerNextXp: 2000,
      source: 1, dailymission: { d1: { count: 1, complete: false } }, locale: 'en', soundEffect: false });
    send('LOAD_LOBBY', players);
    send('NEARBY_PLAYERS', [{ playerSource: 4, playerIdentifier: 'ID4', playerName: 'Carl Johnson', playerLevel: 2, playerImage: avatar(4), distance: 3 }]);
    send('LEADERBOARD_ENABLED', true);
    send('LOAD_HISTORY', [{ historyRegionID: 1, historyTotalScore: 48, historyTime: '16-09-2026 14:35', historyPlayers: [{ playerName: 'John Doe' }, { playerName: 'Jane Roe' }], historyRewardXP: 1000, historyRewardMoney: 7500 }]);
  }

  window.TwJobMock = {
    send,
    posted(name, data) {
      console.log('[preview] NUI callback', name, data === undefined ? '' : JSON.stringify(data));
      if (name === 'selectRegion') send('REFRESH_LOBBY', data || false);
      if (name === 'getLeaderboard') send('LOAD_LEADERBOARD', [1, 2, 3, 4, 5].map(i => ({ playerIdentifier: 'ID' + i,
        playerName: ['John Doe', 'Jane Roe', 'Ali Demir', 'Carl Johnson', 'Mia Wong'][i - 1], playerLevel: 30 - i * 4,
        playerImage: avatar(i), moneyEarned: 250000 / i, tasksDone: [12, 40, 18, 7, 25][i - 1] })));
    },
    show(screen) {
      if (screen === 'menu') { send('OPEN_MENU', JSON.parse(JSON.stringify(window.__twJob.playerData))); return; }
      if (screen === 'hud') {
        send('START_JOB', { Players: players.map(p => Object.assign({ scoreAmount: 14, bonusScoreAmount: 2 }, p)), regionJobTask: tasks, bonusJobTask: [] });
        send('UPDATE_PROGRESS', { label: 'Mow the lawn', completed: 12, required: 25, overall: 42, version: 1 });
      }
      if (screen === 'invite') send('INVITE_MENU', { lobbyOwner: 'John Doe', identifier: 'ID1' });
      if (screen === 'finish') send('FINISH_JOB', { historyRegionName: 'Richman', historyTotalScore: 48, historyBonusScore: 6, historyRewardXP: 1000,
        historyTotalMoney: 12500, historyBonusMoney: 500, historyPlayers: players.map(p => Object.assign({ scoreAmount: 16, bonusScoreAmount: 2, isOwner: p.playerOwner }, p)) });
      if (screen === 'notify') ['success', 'error', 'info'].forEach((type, i) => send('NOTIFICATION', { type, message: 'This is a ' + type + ' notification', duration: 8000 + i }));
      if (screen === 'progress') send('showProgressBar', { label: 'Trimming the bush', time: 6 });
      if (screen === 'tutorial') { send('CLOSENUI'); send('OPEN_TUTORIAL'); }
      if (screen === 'hint') send('HINT_CARD_SHOW', { title: 'Packing the box',
        body: 'Drag a folded piece onto the box on the table. The see-through copy in the box shows its place.',
        closeLabel: 'Close', neverLabel: "Don't show again" });
    },
  };
  boot();
})();
