window.TwPages = window.TwPages || {};
TwPages.overview = {
  data: () => ({ metric: 'money' }),
  computed: {
    d() { return Tw.store.data.overview; },
    series() { return (this.d && this.d.series) || { labels: [], jobs: [] }; },
    totals() {
      const out = { money: [], xp: [], sessions: [] };
      this.series.labels.forEach((_, i) => {
        for (const key of ['money', 'xp', 'sessions']) out[key][i] = this.series.jobs.reduce((s, j) => s + (Number(j[key][i]) || 0), 0);
      });
      return out;
    },
    labels() {
      return this.series.labels.map(l => (this.series.unit === 'hour' ? l : Tw.fmt.day(l)));
    },
    format() {
      return this.metric === 'money' ? Tw.fmt.money : Tw.fmt.num;
    },
    shareTotal() { return ((this.d && this.d.share) || []).reduce((s, r) => s + (Number(r.money) || 0), 0); },
  },
  methods: {
    kpi(key) { return (this.d && this.d.kpi && this.d.kpi[key]) || { value: 0, prev: null }; },
    delta(key) { const k = this.kpi(key); return Tw.fmt.delta(k.value, k.prev); },
    areaConfig() {
      const series = this.series.jobs.map(j => ({ label: Tw.job.name(j.job), color: Tw.job.color(j.job), data: j[this.metric] }));
      return TwCharts.area(this.labels, series, this.format);
    },
    shareConfig() {
      const items = (this.d.share || []).map(r => ({ label: Tw.job.name(r.job), value: r.money, color: Tw.job.color(r.job) }));
      return TwCharts.doughnut(items, Tw.fmt.money);
    },
    openLive() { Tw.store.page = 'live'; Tw.api.load('live'); },
  },
  template: `
  <div class="page fit">
    <template v-if="!d">
      <div class="grid g4"><tw-skel v-for="i in 4" :key="i" height="9rem"/></div>
      <div class="grid g21"><tw-skel height="100%"/><tw-skel height="100%"/></div>
      <div class="grid g21"><tw-skel height="100%"/><tw-skel height="100%"/></div>
    </template>
    <template v-else>
      <div class="grid g4">
        <tw-kpi :label="t('overview.paid')" icon="coins" :value="fmt.moneyShort(kpi('money').value)" :title="fmt.money(kpi('money').value)"
          :delta="delta('money')" :spark="totals.money" :color="palette.money"/>
        <tw-kpi :label="t('overview.finished')" icon="circle-check" :value="fmt.num(kpi('sessions').value)"
          :delta="delta('sessions')" :spark="totals.sessions" :color="palette.accent"/>
        <tw-kpi :label="t('overview.working')" icon="activity" :value="fmt.num(d.working.players)"
          :note="t('overview.lobbies', { n: d.working.lobbies })"/>
        <tw-kpi :label="t('overview.perHour')" icon="clock" :value="fmt.moneyShort(kpi('perHour').value)" :title="fmt.money(kpi('perHour').value)"
          :delta="delta('perHour')" :note="t('overview.perHourNote')"/>
      </div>

      <div class="grid g21">
        <div class="card col">
          <div class="card-head">
            <h3>{{ t('overview.inflow') }}</h3>
            <div class="right seg">
              <button v-for="m in ['money', 'xp', 'sessions']" :key="m" :class="{ on: metric === m }" @click="metric = m">{{ t('overview.metric.' + m) }}</button>
            </div>
          </div>
          <div class="card-body">
            <tw-chart v-if="series.labels.length" :config="areaConfig" :deps="[series, metric]" height="100%"/>
            <tw-empty v-else icon="activity" :title="t('empty.noData')" :text="t('empty.noDataHint')"/>
          </div>
        </div>
        <div class="card col">
          <div class="card-head"><h3>{{ t('overview.share') }}</h3></div>
          <div class="card-body">
            <template v-if="shareTotal">
              <tw-chart :config="shareConfig" :deps="d.share" height="100%"/>
              <div class="legend">
                <div class="legend-row" v-for="r in d.share" :key="r.job">
                  <tw-job :res="r.job" link/><span class="r">{{ fmt.moneyShort(r.money) }}</span>
                  <span class="pct">{{ Math.round(r.money / shareTotal * 100) }}%</span>
                </div>
              </div>
            </template>
            <tw-empty v-else icon="coins" :title="t('empty.noData')"/>
          </div>
        </div>
      </div>

      <div class="grid g21">
        <div class="card col">
          <div class="card-head"><h3>{{ t('overview.top') }}</h3></div>
          <div class="card-body tbl-wrap scroll">
            <table class="tbl" v-if="d.top.length">
              <thead><tr><th>{{ t('col.player') }}</th><th>{{ t('col.job') }}</th><th class="r">{{ t('col.earned') }}</th>
                <th class="r">{{ t('col.sessions') }}</th><th class="r">{{ t('col.perHour') }}</th></tr></thead>
              <tbody>
                <tr v-for="p in d.top" :key="p.identifier" class="click">
                  <td><tw-player :name="p.name" :identifier="p.identifier"/></td>
                  <td><tw-job :res="p.topJob" link/></td>
                  <td class="r money">{{ fmt.money(p.money) }}</td>
                  <td class="r">{{ fmt.num(p.sessions) }}</td>
                  <td class="r">{{ fmt.moneyShort(p.perHour) }}</td>
                </tr>
              </tbody>
            </table>
            <tw-empty v-else icon="users" :title="t('empty.noPlayers')"/>
          </div>
        </div>
        <div class="card col">
          <div class="card-head"><h3>{{ t('overview.liveNow') }}</h3>
            <div class="right"><button class="link" @click="openLive">{{ t('common.all') }}<tw-icon name="chevron-right"/></button></div>
          </div>
          <div class="card-body scroll">
            <div v-if="d.live.length" class="legend">
              <div class="legend-row" v-for="l in d.live" :key="l.id">
                <tw-job :res="l.job"/><span class="muted">{{ l.region }}</span>
                <span class="r"><span class="pill"><tw-icon name="users"/>{{ l.players }}</span>
                  <span :class="l.started ? 'money' : 'faint'" style="margin-left:.5rem">{{ fmt.clock(l.seconds) }}</span></span>
              </div>
            </div>
            <tw-empty v-else icon="radio" :title="t('live.empty')"/>
          </div>
        </div>
      </div>
    </template>
  </div>`,
};
