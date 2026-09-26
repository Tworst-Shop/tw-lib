window.TwPages = window.TwPages || {};
TwPages.players = {
  data: () => ({ search: '', sort: 'money', desc: true }),
  computed: {
    d() { return Tw.store.data.players; },
    rows() {
      const list = ((this.d && this.d.list) || []).slice();
      const k = this.sort;
      list.sort((a, b) => {
        const x = a[k], y = b[k];
        const r = typeof x === 'string' ? String(x).localeCompare(String(y)) : (Number(x) || 0) - (Number(y) || 0);
        return this.desc ? -r : r;
      });
      return list;
    },
  },
  watch: {
    search(value) {
      clearTimeout(this.debounce);
      this.debounce = setTimeout(() => Tw.api.load('players', { search: value.trim() }), 250);
    },
  },
  methods: {
    by(key) { if (this.sort === key) this.desc = !this.desc; else { this.sort = key; this.desc = true; } },
    farm(p) { return this.d && this.d.avgPerHour > 0 && p.perHour > this.d.avgPerHour * 2; },
    open(p) { Tw.store.drawer = p.identifier; Tw.api.load('player', { identifier: p.identifier }); },
  },
  template: `
  <div class="page">
    <div class="toolbar">
      <div class="search"><tw-icon name="search"/><input class="input" v-model="search" :placeholder="t('players.search')"></div>
    </div>
    <div class="card">
      <div class="card-body tbl-wrap">
        <template v-if="!d"><tw-skel v-for="i in 6" :key="i" height="2.6rem" style="margin:.3rem 0"/></template>
        <tw-empty v-else-if="!rows.length" icon="users" :title="t('empty.noPlayers')" :text="search ? t('players.noMatch') : ''"/>
        <table v-else class="tbl">
          <thead><tr>
            <th class="sort" :class="{ sorted: sort === 'name' }" @click="by('name')">{{ t('col.player') }}</th>
            <th>{{ t('col.topJob') }}</th>
            <th class="r sort" :class="{ sorted: sort === 'money' }" @click="by('money')">{{ t('col.earned') }}</th>
            <th class="r sort" :class="{ sorted: sort === 'sessions' }" @click="by('sessions')">{{ t('col.sessions') }}</th>
            <th class="r sort" :class="{ sorted: sort === 'perHour' }" @click="by('perHour')">{{ t('col.perHour') }}</th>
            <th class="r sort" :class="{ sorted: sort === 'lastSeen' }" @click="by('lastSeen')">{{ t('col.lastJob') }}</th>
          </tr></thead>
          <tbody>
            <tr v-for="p in rows" :key="p.identifier" class="click" @click="open(p)">
              <td><div style="display:flex;align-items:center;gap:.6rem">
                <tw-avatar :name="p.name || p.identifier" :color="p.online ? palette.money : palette.faint"/>
                <tw-player :name="p.name" :identifier="p.identifier"/>
              </div></td>
              <td><tw-job v-if="p.topJob" :res="p.topJob"/></td>
              <td class="r money">{{ fmt.money(p.money) }}</td>
              <td class="r">{{ fmt.num(p.sessions) }}</td>
              <td class="r">
                <span v-if="farm(p)" class="pill warn" :title="t('players.farmHint')" style="margin-right:.4rem"><tw-icon name="triangle-alert"/></span>{{ fmt.moneyShort(p.perHour) }}
              </td>
              <td class="r muted">{{ fmt.time(p.lastSeen) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>`,
};

window.TwComponents['tw-drawer'] = {
  computed: {
    store: () => Tw.store,
    p() { const d = Tw.store.data.player; return d && d.identifier === Tw.store.drawer ? d : null; },
    recent() { return Tw.groupLedger(this.p ? this.p.recent : []); },
  },
  methods: {
    close() { Tw.store.drawer = null; },
    jobsConfig() {
      return TwCharts.hbars(this.p.perJob.map(j => ({ label: Tw.job.name(j.job), value: j.money, color: Tw.job.color(j.job) })), Tw.fmt.money);
    },
    allLedger() {
      Tw.store.page = 'ledger';
      Tw.store.ledgerSearch = this.p.identifier;
      Tw.api.load('ledger', { identifier: this.p.identifier, offset: 0 });
      this.close();
    },
  },
  template: `
  <Transition name="drawer" :duration="{ enter: 340, leave: 200 }">
    <div v-if="store.drawer" class="drawer-layer">
    <div class="drawer-back" @click="close"></div>
    <aside class="drawer">
      <div class="drawer-head">
        <tw-avatar :name="(p && p.name) || store.drawer" :color="p && p.online ? palette.money : palette.faint"/>
        <div style="min-width:0">
          <h2>{{ (p && p.name) || store.drawer }}</h2>
          <div class="faint" style="font-size:.8rem">{{ store.drawer }}<template v-if="p && p.altName"> · {{ p.altName }}</template></div>
        </div>
        <span v-if="p && p.online" class="pill live" style="margin-left:.4rem"><span class="pulse"></span>{{ t('players.online') }}</span>
        <button class="icon-btn" style="margin-left:auto" @click="close"><tw-icon name="x"/></button>
      </div>
      <div class="drawer-body">
        <template v-if="!p"><tw-skel height="6rem"/><tw-skel height="12rem"/></template>
        <template v-else>
          <div class="grid g2">
            <div class="card card-pad"><div class="kpi-label">{{ t('col.earned') }}</div><div class="kpi-value money" style="font-size:1.5rem">{{ fmt.money(p.kpi.money) }}</div></div>
            <div class="card card-pad"><div class="kpi-label">XP</div><div class="kpi-value xp" style="font-size:1.5rem">{{ fmt.num(p.kpi.xp) }}</div></div>
            <div class="card card-pad"><div class="kpi-label">{{ t('col.sessions') }}</div><div class="kpi-value" style="font-size:1.5rem">{{ fmt.num(p.kpi.sessions) }}</div></div>
            <div class="card card-pad"><div class="kpi-label">{{ t('col.perHour') }}</div><div class="kpi-value" style="font-size:1.5rem">{{ fmt.money(p.kpi.perHour) }}</div></div>
          </div>
          <div class="card" v-if="p.perJob.length">
            <div class="card-head"><h3>{{ t('players.byJob') }}</h3></div>
            <div class="card-body"><tw-chart :config="jobsConfig" :deps="p.perJob" :height="(p.perJob.length * 2.4 + 2) + 'rem'"/></div>
          </div>
          <div class="card">
            <div class="card-head"><h3>{{ t('players.recent') }}</h3>
              <div class="right"><button class="link" @click="allLedger">{{ t('players.allRecords') }}<tw-icon name="chevron-right"/></button></div>
            </div>
            <div class="card-body tbl-wrap">
              <table class="tbl" v-if="recent.length">
                <tbody><tr v-for="e in recent" :key="e.key">
                  <td class="muted">{{ fmt.time(e.time) }}</td><td><tw-job :res="e.job"/></td>
                  <td class="r"><span v-if="e.money" class="money">+{{ fmt.money(e.money) }}</span><span v-if="e.taken" class="neg"> -{{ fmt.money(e.taken) }}</span></td>
                  <td class="r xp">{{ e.xp ? fmt.num(e.xp) + ' XP' : '' }}</td>
                </tr></tbody>
              </table>
              <tw-empty v-else icon="scroll-text" :title="t('empty.noData')"/>
            </div>
          </div>
        </template>
      </div>
    </aside>
    </div>
  </Transition>`,
};
