(function () {
  const LIB = window.TW_LIB_JOB || './';
  const inGame = typeof GetParentResourceName === 'function';
  const RESOURCE = inGame ? GetParentResourceName() : 'tw-job-preview';

  async function postNUI(name, data) {
    if (!inGame) { if (window.TwJobMock) window.TwJobMock.posted(name, data); return null; }
    try {
      const response = await fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data),
      });
      if (!response.ok) return null;
      const text = await response.text();
      if (!text) return null;
      try { return JSON.parse(text); } catch (e) { return null; }
    } catch (e) {
      return null;
    }
  }

  const SHARED_SOUNDS = { 'click.wav': true, 'errorclick.mp3': true };
  let audio = null;
  function clicksound(file, enabled) {
    if (enabled == false || enabled == null) return;
    audio = new Audio((SHARED_SOUNDS[file] ? LIB + 'sounds/' : './sounds/') + file);
    audio.volume = 0.4;
    audio.play().catch(() => {});
  }
  function stopsound() {
    if (audio) { audio.pause(); audio = null; }
  }
  window.postNUI = postNUI;
  window.clicksound = clicksound;
  window.stopsound = stopsound;

  function toRgb(color) {
    const text = String(color || '').trim();
    let m = text.match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
    if (m) {
      const hex = m[1].length === 3 ? m[1].split('').map(c => c + c).join('') : m[1];
      return [0, 2, 4].map(i => parseInt(hex.substr(i, 2), 16));
    }
    m = text.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/i);
    return m ? [Number(m[1]), Number(m[2]), Number(m[3])] : null;
  }
  const mix = (rgb, to, amount) => rgb.map(v => Math.round(v + (to - v) * amount));

  function applyTheme(ui) {
    if (!ui) return;
    const root = document.documentElement.style;
    const rgb = toRgb(ui.primary);
    if (rgb) {
      root.setProperty('--primary-color', `rgb(${rgb.join(', ')})`);
      root.setProperty('--primary-rgb', rgb.join(', '));
      root.setProperty('--primary-light', ui.primaryLight || `rgb(${mix(rgb, 255, 0.55).join(', ')})`);
      root.setProperty('--primary-color-transparent', ui.primaryTransparent || `rgba(${mix(rgb, 0, 0.35).join(', ')}, 0.1)`);
      root.setProperty('--primary-color-hover', ui.primaryHover || `rgb(${mix(rgb, 0, 0.4).join(', ')})`);
    }
    if (ui.background) root.setProperty('--background', ui.background);
    if (ui.titleBg) root.setProperty('--title-bg', ui.titleBg);
    if (ui.titleFont) root.setProperty('--title-font', ui.titleFont);
  }

  function previewMission() {
    const players = [1, 2, 3, 4].map(i => ({ scoreAmount: 0, playerName: 'Player ' + i, playerLevel: i,
      playerIdentifier: 'ID00' + i, playerImage: '', bonusScoreAmount: 0, source: 1 }));
    const tasks = [1, 2, 3, 4].map(i => ({ jobLabel: 'Task ' + i, madeAmount: 0, finish: false, img: '',
      jobName: 'task' + i, invisible: false, jobCount: 2 }));
    return { Players: players, regionJobTask: tasks };
  }

  const MOVABLE = { teamList: '.newTeamList', scoreList: '.allScoreList', inviteSide: '.newInviteSide', notificationDiv: '.notifyList' };
  const DEFAULT_POSITIONS = () => ({
    teamList: { top: '77.22vh', left: '85.94vw' },
    scoreList: { top: '2.64vh', left: '1.61vw' },
    inviteSide: { top: '2.85vh', left: '73.07vw' },
    notificationDiv: { top: '40.48vh', left: '81.54vw' },
  });

  const base = {
    data: () => ({
      lib: LIB,
      ui: { logo: '', scoreIcon: '', regionImage: '', scriptName: '' },
      isActive: false,
      notifyShow: false,
      notifications: [],
      progressbar: 0,
      progressbarLabel: '',
      localeValue: 'English',
      state: {
        mainShow: false,
        teamShow: false,
        finishShow: false,
        jobIsActive: false,
        currentPage: 'home',
        missionScoreData: previewMission(),
        languageTitle: [],
        defaultLogo: '',
        serverName: 'TWORST',
        scriptName: '',
        serverMoneyType: '$',
        selectedRegion: false,
        expandedRegion: null,
        autoRegion: false,
        heroPhase: null,
        gridPaging: null,
        jobProgress: null,
        invitePlayerModal: {},
        currentRegionIndex: 0,
        regionsPerPage: 4,
        currentDailyMissionIndex: 0,
        dailyMissionsPerPage: 2,
        slideDirection: 'right',
        settings: { Sounds: true, Language: 'en', moveUI: false, uiPositions: DEFAULT_POSITIONS() },
        nearbyPlayers: [],
        requestData: { show: false, hostIdentifier: '', hostName: '' },
        finishJobData: false,
        locales: {},
        tutorialList: [],
        tutorialOnly: false,
      },
      playerData: {
        playerLevel: 1, playerXp: 0, playerNextXp: 1, playerIdentifier: '', owner: false,
        dailymission: [], playerDailyMission: [], soundEffect: true, locale: 'en',
      },
      playerListData: [],
      rewardSplit: {},
      rewardOpen: false,
      rewardSplitEnabled: false,
      regionData: [],
      historyData: [],
      dailyMission: false,
      hintCard: null,
      leaderboardEnabled: false,
      leaderboardLoaded: false,
      leaderboardData: [],
      leaderboardSort: 'money',
      soundPanelOpen: false,
      soundSettings: [
        { key: 'ui', label: 'Menu / UI', enabled: true, volume: 80 },
        { key: 'notify', label: 'Notifications', enabled: true, volume: 70 },
        { key: 'machine', label: 'Machines', enabled: true, volume: 65 },
      ],
      jobReveal: false,
      teamReveal: false,
      inviteReveal: false,
      invitePicked: null,
      finishReveal: false,
    }),

    watch: {
      'state.teamShow'(val) {
        this.jobReveal = false;
        this.teamReveal = false;
        if (!val) return;
        this.$nextTick(() => {
          setTimeout(() => { this.jobReveal = true; }, 560);
          setTimeout(() => { this.teamReveal = true; }, 450);
        });
      },
      'state.requestData.show'(val) {
        this.inviteReveal = false;
        if (val) this.$nextTick(() => { setTimeout(() => { this.inviteReveal = true; }, 560); });
      },
      'state.finishShow'(val) {
        this.finishReveal = false;
        if (val) this.$nextTick(() => { setTimeout(() => { this.finishReveal = true; }, 420); });
      },
    },

    mounted() {
      window.addEventListener('keyup', this.keyHandler);
      window.addEventListener('message', this.eventHandler);
      document.addEventListener('click', this.handleClickOutside);
      this._nfyId = 0;
      this._nfyTimers = {};
    },
    beforeUnmount() {
      window.removeEventListener('keyup', this.keyHandler);
      window.removeEventListener('message', this.eventHandler);
      document.removeEventListener('click', this.handleClickOutside);
    },

    methods: {
      changePage(page) {
        if (this.state.currentPage == page) return;
        clicksound('click.wav', this.playerData.soundEffect);
        this.state.expandedRegion = null;
        this.state.currentPage = page;
        if (page === 'leaderboard') postNUI('getLeaderboard', {});
      },
      toggleDropdown() { this.isActive = !this.isActive; },
      toggleBox(index) {
        clicksound('click.wav', this.playerData.soundEffect);
        const open = !this.state.tutorialList[index].isOpen;
        this.state.tutorialList.forEach((item, i) => { item.isOpen = i === index && open; });
      },
      selectOption(option) {
        this.isActive = false;
        this.playerData.locale = option.value;
        this.localeValue = option.label;
      },
      handleClickOutside(event) {
        const root = document.getElementById('app');
        if (!root || !root.contains(event.target)) this.isActive = false;
        if (this.soundPanelOpen) {
          const opener = root && root.querySelector('.newSoundOpener');
          if (!opener || !opener.contains(event.target)) this.soundPanelOpen = false;
        }
        if (this.rewardOpen) this.rewardOpen = false;
      },

      rewardPctOf(identifier) {
        const v = this.rewardSplit[identifier];
        return typeof v === 'number' ? Math.round(v) : 0;
      },
      setRewardPct(identifier, raw) {
        let v = Math.round(Number(raw));
        if (!isFinite(v)) return;
        v = Math.max(0, Math.min(100, v));
        const others = this.playerListData.map(p => p.playerIdentifier).filter(id => id && id !== identifier);
        if (!others.length) { this.rewardSplit = { [identifier]: 100 }; return; }
        const rest = 100 - v;
        const cur = others.map(id => this.rewardPctOf(id));
        const curSum = cur.reduce((a, b) => a + b, 0);
        const next = { [identifier]: v };
        let given = 0;
        others.forEach((id, i) => {
          const share = curSum > 0 ? (cur[i] / curSum) * rest : rest / others.length;
          const val = Math.floor(share);
          next[id] = val;
          given += val;
        });
        const leftover = rest - given;
        if (leftover > 0) next[others[0]] += leftover;
        this.rewardSplit = next;
      },
      toggleReward(event) {
        clicksound('click.wav', this.playerData.soundEffect);
        this.rewardOpen = !this.rewardOpen;
        if (!this.rewardOpen) return;
        const button = event && event.currentTarget;
        this.$nextTick(() => requestAnimationFrame(() => this.positionRewardPanel(button)));
      },
      positionRewardPanel(button) {
        const panel = document.querySelector('.rewardPanel');
        if (!button || !panel) return;
        const box = button.getBoundingClientRect();
        let top = box.top - panel.offsetHeight - 8;
        if (top < 8) top = box.bottom + 8;
        let left = box.right - panel.offsetWidth;
        if (left < 8) left = 8;
        panel.style.top = top + 'px';
        panel.style.left = left + 'px';
        panel.style.right = 'auto';
        panel.style.bottom = 'auto';
      },
      stepReward(identifier, delta) {
        clicksound('click.wav', this.playerData.soundEffect);
        this.setRewardPct(identifier, this.rewardPctOf(identifier) + delta);
        this.commitRewardSplit();
      },
      equalSplit() {
        const ids = this.playerListData.map(p => p.playerIdentifier).filter(Boolean);
        if (!ids.length) return;
        clicksound('click.wav', this.playerData.soundEffect);
        const base = Math.floor(100 / ids.length);
        const remainder = 100 - base * ids.length;
        const next = {};
        ids.forEach((id, i) => { next[id] = base + (i < remainder ? 1 : 0); });
        this.rewardSplit = next;
        this.commitRewardSplit();
      },
      fitRewardSplit() {
        const ids = this.playerListData.map(p => p.playerIdentifier).filter(Boolean);
        if (!ids.length) return;
        const total = ids.reduce((sum, id) => sum + (typeof this.rewardSplit[id] === 'number' ? this.rewardSplit[id] : NaN), 0);
        if (total === 100) return;
        const base = Math.floor(100 / ids.length);
        const remainder = 100 - base * ids.length;
        const next = {};
        ids.forEach((id, i) => { next[id] = base + (i < remainder ? 1 : 0); });
        this.rewardSplit = next;
      },
      commitRewardSplit() {
        const payload = {};
        this.playerListData.forEach(p => {
          if (p.playerIdentifier) payload[p.playerIdentifier] = this.rewardPctOf(p.playerIdentifier);
        });
        postNUI('updateRewardSplit', payload);
      },
      prevRegion() {
        if (this.state.currentRegionIndex <= 0) return;
        clicksound('click.wav', this.playerData.soundEffect);
        this.state.slideDirection = 'left';
        this.state.currentRegionIndex -= this.state.regionsPerPage;
        this.pageAnim('left');
      },
      nextRegion() {
        if (this.state.currentRegionIndex + this.state.regionsPerPage >= this.regionData.length) return;
        clicksound('click.wav', this.playerData.soundEffect);
        this.state.slideDirection = 'right';
        this.state.currentRegionIndex += this.state.regionsPerPage;
        this.pageAnim('right');
      },
      pageAnim(direction) {
        this.state.gridPaging = direction;
        clearTimeout(this._pagingTimer);
        this._pagingTimer = setTimeout(() => { this.state.gridPaging = null; }, 550);
      },
      crewLabel(region) {
        const info = region && region.regionInfo;
        if (!info || info.crewMin == null) return this.state.locales['1-4Players'];
        const min = info.crewMin || 1;
        const max = info.crewMax || 0;
        const people = this.state.locales['crewPeople'] || 'Players';
        if (min === 1 && max === 1) return this.state.locales['crewSolo'] || 'SOLO';
        if (max === 0) return `${min}+ ${people}`;
        if (min === max) return `${min} ${people}`;
        return `${min}-${max} ${people}`;
      },
      crewIncompatible(region) {
        const info = region && region.regionInfo;
        if (!info || info.crewMin == null) return false;
        const crew = this.playerListData.length;
        const min = info.crewMin || 1;
        const max = info.crewMax || 0;
        return crew < min || (max > 0 && crew > max);
      },
      onRegionClick(region, event) {
        if (region == null) return;
        this.expandRegion(region, event.currentTarget);
        const alreadySelected = this.state.selectedRegion && this.state.selectedRegion.regionID === region.regionID;
        if (!alreadySelected) this.selectRegion(region);
      },
      heroRects(cardEl, hero) {
        const op = hero.offsetParent;
        if (!op) return null;
        const parent = op.getBoundingClientRect();
        const from = cardEl.getBoundingClientRect();
        const to = hero.getBoundingClientRect();
        const box = r => ({ top: `${r.top - parent.top}px`, left: `${r.left - parent.left}px`, width: `${r.width}px`, height: `${r.height}px` });
        return { from: box(from), to: box(to) };
      },
      expandRegion(region, cardEl) {
        this.state.expandedRegion = region;
        this.state.heroPhase = 'expanding';
        this.$nextTick(() => {
          const hero = this.$refs.heroCard;
          if (!hero || !cardEl) { this.state.heroPhase = null; return; }
          const r = this.heroRects(cardEl, hero);
          if (r && typeof hero.animate === 'function') {
            hero.animate([r.from, r.to], { duration: 680, easing: 'cubic-bezier(0.16, 1, 0.3, 1)' });
          }
          setTimeout(() => { if (this.state.heroPhase === 'expanding') this.state.heroPhase = null; }, 180);
        });
      },
      pickOnlyRegion() {
        if (!this.state.autoRegion || this.regionData.length !== 1 || !this.playerListData.length) return;
        this.state.autoRegion = false;
        const region = this.regionData[0];
        if (this.state.jobIsActive) return;
        this.state.expandedRegion = region;
        const level = region.regionInfo ? region.regionInfo.regionMinimumLevel || 0 : 0;
        if (this.isPlayerOwner && !this.state.selectedRegion && level <= this.playerData.playerLevel) postNUI('selectRegion', region);
      },
      collapseHero() {
        if (!this.state.expandedRegion) { this.state.heroPhase = null; return; }
        clicksound('click.wav', this.playerData.soundEffect);
        this.state.expandedRegion = null;
        this.state.heroPhase = 'restoring';
        if (this.isPlayerOwner && this.state.selectedRegion) postNUI('selectRegion', false);
        setTimeout(() => { if (this.state.heroPhase === 'restoring') this.state.heroPhase = null; }, 700);
      },
      setLeaderboardSort(metric) {
        if (this.leaderboardSort === metric) return;
        clicksound('click.wav', this.playerData.soundEffect);
        this.leaderboardSort = metric;
      },
      toggleSoundPanel() {
        clicksound('click.wav', this.playerData.soundEffect);
        this.soundPanelOpen = !this.soundPanelOpen;
      },
      closeSoundPanel() { this.soundPanelOpen = false; },
      updateSound(s) {
        if (s.key === 'ui') this.playerData.soundEffect = s.enabled;
        postNUI('updateSoundSetting', { key: s.key, enabled: s.enabled, volume: s.volume });
      },

      pushNotify(payload) {
        payload = payload || {};
        if (!payload.message) return;
        if (this.notifications.some(n => n.message === payload.message)) return;
        const id = ++this._nfyId;
        const raw = String(payload.type || 'info');
        const type = /^succ/i.test(raw) ? 'success' : /err|fail/i.test(raw) ? 'error' : 'info';
        const item = { id, expanded: false, preview: !!payload.preview, type,
          message: String(payload.message), duration: Math.max(1200, Number(payload.duration) || 5000) };
        this.notifications.push(item);
        this.notifyShow = true;
        const EXPAND = 180;
        setTimeout(() => { const it = this.notifications.find(x => x.id === id); if (it) it.expanded = true; }, EXPAND);
        if (!item.preview) this._nfyTimers[id] = setTimeout(() => this.removeNotify(id), EXPAND + item.duration);
      },
      removeNotify(id) {
        const i = this.notifications.findIndex(x => x.id === id);
        if (i !== -1) this.notifications.splice(i, 1);
        if (this._nfyTimers[id]) { clearTimeout(this._nfyTimers[id]); delete this._nfyTimers[id]; }
        if (this.notifications.length === 0) this.notifyShow = false;
      },
      beforeNfyLeave(el) {
        el.style.left = el.offsetLeft + 'px';
        el.style.top = el.offsetTop + 'px';
        el.style.width = el.offsetWidth + 'px';
      },

      inviteAnchorCss() {
        const p = this.state.settings.uiPositions.inviteSide || {};
        const css = { top: p.top, left: '', right: '' };
        if (p.right != null) { css.right = p.right; return css; }
        if (p.left == null) return css;
        const u = Math.min(window.innerWidth / 100, window.innerHeight * 0.017778);
        const CARD_W = 25.5208 * u;
        const leftPx = (parseFloat(p.left) / 100) * window.innerWidth;
        css.right = (Math.max(window.innerWidth - leftPx - CARD_W, 0) / window.innerWidth * 100).toFixed(2) + 'vw';
        return css;
      },
      prevDailyMission() {
        if (this.state.currentDailyMissionIndex > 0) this.state.currentDailyMissionIndex -= this.state.dailyMissionsPerPage;
      },
      nextDailyMission() {
        if (this.state.currentDailyMissionIndex + this.state.dailyMissionsPerPage < this.playerData.playerDailyMission.length) {
          this.state.currentDailyMissionIndex += this.state.dailyMissionsPerPage;
        }
      },
      invitePlayer(playerID) {
        if (playerID == null || playerID < 0) return;
        clicksound('click.wav', this.playerData.soundEffect);
        postNUI('invitePlayer', playerID);
      },
      acceptInvite() { this.pickInvite('accept'); },
      denyInvite() { this.pickInvite('reject'); },
      pickInvite(type, visualOnly) {
        if (this.invitePicked || this.state.settings.moveUI) return;
        this.invitePicked = type;
        clicksound('click.wav', this.playerData.soundEffect);
        setTimeout(() => { this.inviteReveal = false; }, 450);
        setTimeout(() => {
          if (!visualOnly) postNUI(type === 'accept' ? 'acceptInvite' : 'declineInvite', this.state.requestData.identifier);
          this.state.requestData.show = false;
          this.invitePicked = null;
        }, 1150);
      },
      isAway(playerIdentifier) {
        return this.playerListData.some(p => p.offline && p.playerIdentifier === playerIdentifier);
      },
      kickPlayer(playerIdentifier) {
        if (!playerIdentifier) return;
        const targetPlayer = this.playerListData.find(x => x.playerIdentifier === playerIdentifier);
        const ownerPlayer = this.playerListData.find(x => x.playerOwner === true);
        if (!targetPlayer || !ownerPlayer) return;
        if (playerIdentifier === this.playerData.playerIdentifier) {
          postNUI('leaveLobby', ownerPlayer.playerIdentifier);
          return;
        }
        if (targetPlayer.playerIdentifier === ownerPlayer.playerIdentifier) {
          clicksound('errorclick.mp3', this.playerData.soundEffect);
          return;
        }
        clicksound('click.wav', this.playerData.soundEffect);
        postNUI('kickPlayer', { lobbyID: ownerPlayer.playerIdentifier, identifier: playerIdentifier, targetID: targetPlayer.source });
      },
      selectRegion(regionValue) {
        if (regionValue == null || this.playerData.playerIdentifier == null) return;
        const me = this.playerListData.find(x => x.playerIdentifier == this.playerData.playerIdentifier);
        const owner = this.playerListData.find(x => x.playerOwner == true);
        if (!me || !owner || me.playerIdentifier !== owner.playerIdentifier) return;
        if (this.state.selectedRegion && regionValue.regionID == this.state.selectedRegion.regionID) {
          clicksound('click.wav', this.playerData.soundEffect);
          postNUI('selectRegion', false);
          return;
        }
        if (!regionValue.regionID || regionValue.regionID == -1) return;
        if (regionValue.regionInfo.regionMinimumLevel > this.playerData.playerLevel) {
          clicksound('errorclick.mp3', this.playerData.soundEffect);
          this.pushNotify({ message: this.state.locales['joblevelnotenough'] || 'Your level is not enough for this region.', type: 'error' });
          return;
        }
        clicksound('click.wav', this.playerData.soundEffect);
        postNUI('selectRegion', regionValue);
      },
      startJob() {
        if (this.startBlocked) { clicksound('errorclick.mp3', this.playerData.soundEffect); return; }
        if (this.state.jobIsActive) {
          clicksound('click.wav', this.playerData.soundEffect);
          if (!this.isPlayerOwner) {
            const ownerPlayer = this.playerListData.find(x => x.playerOwner === true);
            if (ownerPlayer) postNUI('leaveLobby', ownerPlayer.playerIdentifier);
          } else {
            postNUI('resetJob');
          }
        } else if (this.state.selectedRegion) {
          clicksound('click.wav', this.playerData.soundEffect);
          postNUI('startJob', this.state.selectedRegion);
        }
      },
      leaveOtherJob() {
        this.playerData = Object.assign({}, this.playerData, { otherJob: null });
        postNUI('leaveOtherJob');
      },
      closeNUI() {
        this.state.mainShow = false;
        this.state.expandedRegion = null;
        this.state.tutorialOnly = false;
        postNUI('closeNUI');
      },
      closeInviteNUI() {
        this.state.requestData.show = false;
      },

      keyHandler(event) {
        if (this.state.requestData && this.state.requestData.show && !this.invitePicked) {
          if (event.keyCode === 89) { this.acceptInvite(); return; }
          if (event.keyCode === 78) { this.denyInvite(); return; }
        }
        if (event.keyCode == 27 && escapes.some(fn => fn.call(this) === true)) return;
        if (event.keyCode == 27 && this.state.expandedRegion) { this.collapseHero(); return; }
        if (event.keyCode == 27) {
          if (this.state.mainShow && this.state.currentPage === 'tutorial') {
            postNUI('closeTutoNUI');
            this.closeNUI();
          } else if (!this.state.settings.moveUI) {
            this.closeNUI();
          } else {
            this.exitMoveMode();
          }
        }
        if (event.keyCode == 13 && this.state.settings.moveUI) this.exitMoveMode();
      },
      exitMoveMode() {
        this.state.settings.moveUI = false;
        this.state.teamShow = false;
        this.state.requestData.show = false;
        this.state.mainShow = true;
        this.state.currentPage = 'settings';
        this.notifications.filter(n => n.preview).forEach(n => this.removeNotify(n.id));
      },
      formatNumber(number) {
        if (number == null) return 0;
        const tag = { tr: 'tr-TR', de: 'de-DE', fr: 'fr-FR', pt: 'pt-BR', ru: 'ru-RU' }[this.playerData.locale] || 'en-US';
        return Number(number).toLocaleString(tag);
      },
      calculateProgress(mission, complete) { return (mission / complete) * 100; },
      mergeData(sqlData, configData) {
        if (sqlData == null || configData == null) return;
        this.playerData.playerDailyMission = configData.map(mission => {
          const row = sqlData[mission.name];
          return Object.assign({}, mission, {
            complete: row ? row.complete : false,
            currentCount: row ? row.count : 0,
            progressbar: row ? this.calculateProgress(row.count, mission.count) : 0,
          });
        });
      },
      moveUI() {
        if (this.state.jobIsActive) return;
        this.state.settings.moveUI = true;
        this.state.mainShow = false;
        this.state.teamShow = true;
        this.state.requestData.show = true;
        this.state.requestData.lobbyOwner = 'Player';
        this.pushNotify({ message: this.state.locales['moveNotice'] || 'Drag the panels, press Enter when done', type: 'info', preview: true });
        this.$nextTick(() => {
          this.applyUIPositions();
          this.makeAllUIDraggable();
        });
      },
      applyUIPositions() {
        const positions = this.state.settings.uiPositions || DEFAULT_POSITIONS();
        for (const key in MOVABLE) {
          const el = document.querySelector(MOVABLE[key]);
          if (!el) continue;
          Object.assign(el.style, key === 'inviteSide' ? this.inviteAnchorCss() : (positions[key] || {}));
          el.style.position = this.state.settings.moveUI ? 'absolute' : '';
          el.style.zIndex = this.state.settings.moveUI ? '999' : '';
        }
      },
      makeElementDraggable(selector, positionKey) {
        const el = document.querySelector(selector);
        if (!el || el._twDrag) return;
        el._twDrag = true;
        el.addEventListener('pointerdown', down => {
          if (!this.state.settings.moveUI) return;
          down.preventDefault();
          const start = el.getBoundingClientRect();
          const dx = down.clientX - start.left;
          const dy = down.clientY - start.top;
          const move = e => {
            el.style.left = Math.min(Math.max(e.clientX - dx, 0), window.innerWidth - start.width) + 'px';
            el.style.top = Math.min(Math.max(e.clientY - dy, 0), window.innerHeight - start.height) + 'px';
            el.style.right = '';
          };
          const up = () => {
            window.removeEventListener('pointermove', move);
            window.removeEventListener('pointerup', up);
            const r = el.getBoundingClientRect();
            const top = (r.top / window.innerHeight * 100).toFixed(2) + 'vh';
            if (positionKey === 'inviteSide') {
              const right = (Math.max(window.innerWidth - r.right, 0) / window.innerWidth * 100).toFixed(2) + 'vw';
              this.state.settings.uiPositions[positionKey] = { top, right };
              el.style.left = '';
              el.style.right = right;
              return;
            }
            this.state.settings.uiPositions[positionKey] = { top, left: (r.left / window.innerWidth * 100).toFixed(2) + 'vw' };
          };
          window.addEventListener('pointermove', move);
          window.addEventListener('pointerup', up);
        });
      },
      makeAllUIDraggable() {
        for (const key in MOVABLE) this.makeElementDraggable(MOVABLE[key], key);
      },
      saveSettings() {
        postNUI('saveSettings', {
          uiPositions: this.state.settings.uiPositions,
          soundEffect: this.playerData.soundEffect,
          locale: this.playerData.locale,
        });
        this.state.settings.moveUI = false;
        this.notifications.filter(n => n.preview).forEach(n => this.removeNotify(n.id));
      },
      resetSettings() {
        this.state.settings.uiPositions = {
          teamList: { top: '77.22vh', left: '85.94vw' },
          scoreList: { top: '0vh', left: '1.30vw' },
          inviteSide: { top: '0vh', left: '74.48vw' },
          notificationDiv: { top: '20vh', left: '1vw' },
        };
        this.applyUIPositions();
      },
      startProgress(label, time) {
        this.progressbarLabel = label;
        this.progressbar = 0;
        const duration = time * 1000;
        let startTime = null;
        const animate = timestamp => {
          if (!startTime) startTime = timestamp;
          const elapsed = timestamp - startTime;
          this.progressbar = Math.min((elapsed / duration) * 100, 100);
          if (elapsed < duration) return requestAnimationFrame(animate);
          setTimeout(() => { stopsound(); this.progressbar = 0; this.progressbarLabel = ''; }, 100);
        };
        requestAnimationFrame(animate);
      },
      resetJobState() {
        this.state.finishShow = true;
        this.state.teamShow = false;
        this.state.mainShow = false;
        this.state.selectedRegion = false;
        this.state.jobIsActive = false;
        this.state.currentPage = 'home';
        this.state.missionScoreData = previewMission();
      },

      eventHandler(event) {
        const data = event.data || {};
        const payload = data.payload;
        switch (data.action) {
          case 'CHECK_NUI': postNUI('checkNUI'); break;
          case 'CLOSENUI': this.closeNUI(); break;
          case 'OPEN_MENU':
            this.state.mainShow = true;
            this.state.tutorialOnly = false;
            if (this.state.currentPage === 'tutorial') this.state.currentPage = 'home';
            this.playerData = Object.assign({ playerDailyMission: [] }, payload);
            if (payload && payload.uiSettings && payload.uiSettings.uiPositions) {
              this.state.settings.uiPositions = payload.uiSettings.uiPositions;
              this.$nextTick(() => this.applyUIPositions());
            }
            this.mergeData(this.playerData.dailymission, this.dailyMission);
            this.state.autoRegion = true;
            this.pickOnlyRegion();
            (this.state.languageTitle || []).forEach(item => {
              if (item.value == this.playerData.locale) this.localeValue = item.label;
            });
            break;
          case 'LOAD_LOBBY': this.playerListData = payload || []; this.pickOnlyRegion(); break;
          case 'LOBBY_REWARDS': this.rewardSplit = payload || {}; this.fitRewardSplit(); break;
          case 'REWARD_SPLIT_ENABLED': this.rewardSplitEnabled = payload !== false; break;
          case 'LOAD_HISTORY': this.historyData = payload || []; break;
          case 'JOB_IS_ACTIVE': this.state.jobIsActive = payload; break;
          case 'REFRESH_LOBBY': {
            this.state.selectedRegion = payload || false;
            const hero = this.state.expandedRegion;
            if (hero && this.regionData.length > 1 && (!payload || hero.regionID !== payload.regionID)) {
              this.state.expandedRegion = payload ? (this.regionData.find(r => r.regionID === payload.regionID) || payload) : null;
            }
            break;
          }
          case 'STATE':
            this.state.serverName = payload.serverName;
            this.state.serverMoneyType = payload.serverMoneyType;
            this.dailyMission = payload.dailyMission;
            this.regionData = payload.regionData || [];
            this.state.tutorialList = payload.tutorialList || [];
            this.state.locales = payload.locales || {};
            this.state.languageTitle = payload.languageTitle || [];
            this.state.defaultLogo = payload.defaultLogo;
            if (payload.uiPositions) {
              this.state.settings.uiPositions = payload.uiPositions;
              this.$nextTick(() => this.applyUIPositions());
            }
            if (payload.ui) {
              Object.assign(this.ui, payload.ui);
              if (payload.ui.scriptName) this.state.scriptName = payload.ui.scriptName;
              applyTheme(payload.ui);
            }
            break;
          case 'UPDATE_LOCALES': this.state.locales = payload || {}; break;
          case 'NEARBY_PLAYERS': this.state.nearbyPlayers = payload || []; break;
          case 'INVITE_MENU':
            this.state.requestData = Object.assign({}, payload, { show: true });
            break;
          case 'START_JOB':
            this.state.mainShow = false;
            this.state.missionScoreData = payload;
            this.state.teamShow = true;
            break;
          case 'REFRESH_JOBTASK': this.state.missionScoreData = payload; break;
          case 'FINISH_JOB':
            if (this.state.mainShow) postNUI('releaseMenu');
            this.state.jobProgress = null;
            this.state.expandedRegion = null;
            this.resetJobState();
            this.state.finishJobData = payload;
            break;
          case 'RESET_JOB':
            this.resetJobState();
            this.state.finishJobData = false;
            this.closeNUI();
            break;
          case 'CLOSE_INVITE_MENU':
            clicksound('click.wav', this.playerData.soundEffect);
            this.closeInviteNUI();
            break;
          case 'CLOSE_FINISH_JOB':
            this.state.finishShow = false;
            this.state.finishJobData = false;
            break;
          case 'LOAD_SETTINGS':
            if (payload && payload.uiPositions) this.state.settings.uiPositions = payload.uiPositions;
            this.$nextTick(() => this.applyUIPositions());
            break;
          case 'EDIT_SETTINGS':
            this.state.settings.moveUI = true;
            this.state.mainShow = false;
            this.state.teamShow = true;
            this.$nextTick(() => { this.applyUIPositions(); this.makeAllUIDraggable(); });
            break;
          case 'NOTIFICATION': this.pushNotify(payload); break;
          case 'INVITE_PICK': this.pickInvite(payload, true); break;
          case 'HINT_CARD_SHOW': this.hintCard = payload || null; break;
          case 'HINT_CARD_HIDE': this.hintCard = null; break;
          case 'LEADERBOARD_ENABLED':
            this.leaderboardEnabled = payload !== false;
            if (!this.leaderboardEnabled && this.state.currentPage === 'leaderboard') this.state.currentPage = 'home';
            break;
          case 'LOAD_LEADERBOARD':
            this.leaderboardData = payload || [];
            this.leaderboardLoaded = true;
            break;
          case 'UPDATE_PROGRESS': {
            const cur = this.state.jobProgress;
            if (!payload) break;
            if (cur && typeof payload.version === 'number' && typeof cur.version === 'number' && payload.version < cur.version) break;
            this.state.jobProgress = payload;
            break;
          }
          case 'HIDE_PROGRESS': this.state.jobProgress = null; break;
          case 'showProgressBar': this.startProgress(payload.label, payload.time); break;
          case 'playSound': clicksound(payload.sound, this.playerData.soundEffect); break;
          case 'CLEAR_COOP_DATA':
            this.resetJobState();
            this.state.finishJobData = false;
            break;
          case 'OPEN_TUTORIAL':
            if (this.state.settings.moveUI) return;
            this.state.tutorialList.forEach(item => { item.isOpen = false; });
            this.state.tutorialOnly = !this.state.mainShow;
            this.state.mainShow = true;
            this.state.currentPage = 'tutorial';
            break;
          default: {
            const handler = actions[data.action];
            if (handler) handler.call(this, payload);
          }
        }
      },
    },

    computed: {
      cpDashoffset() {
        const c = 2 * Math.PI * 18;
        const p = Math.min(Math.max(this.progressbar, 0), 100);
        return c * (1 - p / 100);
      },
      sortedLeaderboard() {
        const key = this.leaderboardSort === 'tasks' ? 'tasksDone' : 'moneyEarned';
        return [...(this.leaderboardData || [])].sort((a, b) => (b[key] || 0) - (a[key] || 0));
      },
      heroMedia() {
        const region = this.state.expandedRegion;
        const info = region && region.regionInfo;
        if (info && info.regionMedia) return info.regionMedia;
        if (info && info.regionImage) return './img/' + info.regionImage;
        return this.ui.regionImage;
      },
      startBlocked() {
        if (this.state.jobIsActive) return false;
        const region = this.state.selectedRegion;
        return region ? this.crewIncompatible(region) : false;
      },
      startBlockedText() {
        const region = this.state.selectedRegion;
        if (!region) return '';
        return `${this.state.locales['crewRequire'] || 'THIS REGION REQUIRES'} ${this.crewLabel(region)}`;
      },
      visibleJobTasks() {
        return (this.state.missionScoreData && this.state.missionScoreData.regionJobTask) || [];
      },
      isPlayerOwner() {
        const ownerPlayer = this.playerListData.find(x => x.playerOwner === true);
        return !!ownerPlayer && this.playerData.playerIdentifier === ownerPlayer.playerIdentifier;
      },
      canSplitRewards() {
        return this.rewardSplitEnabled && this.isPlayerOwner && !this.state.jobIsActive && this.playerListData.length > 1;
      },
      rewardTotal() {
        return this.playerListData.reduce((sum, p) => sum + this.rewardPctOf(p.playerIdentifier), 0);
      },
      myRewardPct() {
        const id = this.playerData && this.playerData.playerIdentifier;
        if (!id) return null;
        const v = this.rewardSplit[id];
        return typeof v === 'number' ? Math.round(v) : null;
      },
      startButtonText() {
        if (this.state.jobIsActive) {
          if (!this.isPlayerOwner) return this.state.locales['leaveLobby'] || 'Leave Lobby';
          return this.state.locales['jobReset'];
        }
        return this.state.locales['jobStart'];
      },
      progressPercentage() {
        if (this.playerData.playerXp == null || this.playerData.playerNextXp == null) return 0;
        return Math.min((this.playerData.playerXp / this.playerData.playerNextXp) * 100, 100);
      },
      displayedRegions() {
        return this.regionData.slice(this.state.currentRegionIndex, this.state.currentRegionIndex + this.state.regionsPerPage);
      },
      displayedDailyMission() {
        const list = this.playerData.playerDailyMission || [];
        return list.slice(this.state.currentDailyMissionIndex, this.state.currentDailyMissionIndex + this.state.dailyMissionsPerPage);
      },
      canGoNext() { return this.state.currentRegionIndex + this.state.regionsPerPage < this.regionData.length; },
      canGoPrev() { return this.state.currentRegionIndex > 0; },
      canGoNextDailyMission() {
        return this.state.currentDailyMissionIndex + this.state.dailyMissionsPerPage < (this.playerData.playerDailyMission || []).length;
      },
      canGoPrevDailyMission() { return this.state.currentDailyMissionIndex > 0; },
      inviteSlots() {
        const missing = 4 - (this.playerListData.length + Object.values(this.state.nearbyPlayers || {}).length);
        return missing > 0 ? missing : 0;
      },
    },
  };

  const extensions = [];
  const actions = {};
  const escapes = [];
  const PART_ORDER = ['menu', 'invite', 'hud', 'finish', 'notify', 'progress', 'hint'];

  window.TwJob = {
    postNUI, clicksound, stopsound, applyTheme,

    extend(extension) {
      extensions.push(extension);
      Object.assign(actions, extension.actions || {});
      if (extension.escape) escapes.push(extension.escape);
    },

    mount(selector) {
      const defaults = Object.assign({}, ...extensions.map(e => e.ui || {}));
      const pages = extensions.flatMap(e => e.pages || []);
      const tabs = pages.map(p => `
            <div class="newCategory" v-if="!state.tutorialOnly"
              :class="state.currentPage == '${p.key}' ? 'newSelectCategory' : ''"
              @click="changePage('${p.key}')">
              <i class="ncIcon" style="-webkit-mask-image:url(${p.icon});mask-image:url(${p.icon})"></i>
              <span class="ncLabel">{{state.locales['${p.label}'] || '${p.fallback || p.key}'}}</span>
            </div>`).join('');
      const parts = Object.assign({}, TwJobParts, {
        menu: TwJobParts.menu.replace('<tw-job-tabs></tw-job-tabs>', tabs)
          .replace('<tw-job-pages></tw-job-pages>', pages.map(p => p.template).join('\n')),
      });
      const template = PART_ORDER.map(name => parts[name]).join('\n') +
        extensions.map(e => e.template || '').join('\n');
      const mixins = extensions.map(e => {
        const { ui, template: _t, actions: _a, escape: _e, pages: _p, ...mixin } = e;
        return mixin;
      });
      const app = Vue.createApp(Object.assign({}, base, { mixins, template }));
      const vm = app.mount(selector || '#app');
      Object.assign(vm.ui, defaults);
      if (defaults.scriptName) vm.state.scriptName = defaults.scriptName;
      applyTheme(defaults);
      window.__twJob = vm;
      return vm;
    },
  };
})();
