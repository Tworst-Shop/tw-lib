window.TwPages = window.TwPages || {};
TwPages.jobs = {
  computed: {
    store: () => Tw.store,
    list() { const d = Tw.store.data.jobs; return d ? d.list || [] : null; },
    detail() { const d = Tw.store.data.job; return d && d.resource === Tw.store.jobDetail ? d : null; },
    regionAverage() {
      const regions = (this.detail && this.detail.regions) || [];
      const money = regions.reduce((s, r) => s + r.money, 0);
      const seconds = regions.reduce((s, r) => s + r.avgDuration * r.sessions, 0);
      return seconds ? money * 3600 / seconds : 0;
    },
    regionMax() { return Math.max(1, ...((this.detail && this.detail.regions) || []).map(r => r.perHour)); },
  },
  methods: {
    open(res) { Tw.store.jobDetail = res; Tw.api.load('job', { resource: res }); },
    delta(k) { return k ? Tw.fmt.delta(k.value, k.prev) : null; },
    comboConfig() {
      const s = this.detail.series;
      return TwCharts.combo(s.labels.map(Tw.fmt.day), { label: Tw.t('col.earned'), data: s.money },
        { label: Tw.t('col.sessions'), data: s.sessions }, Tw.job.color(this.detail.resource), Tw.fmt.money);
    },
    sparkConfig(j) { return () => TwCharts.spark(j.spark, Tw.job.color(j.job)); },
    generous(r) { return this.regionAverage > 0 && r.perHour > this.regionAverage * 1.5; },
    tune() { this.goSettings(this.detail.resource); },
    goLedger(res) { Tw.store.page = 'ledger'; Tw.store.ledgerJob = res; Tw.api.load('ledger', { resource: res, offset: 0 }); },
    goSettings(res) { Tw.store.page = 'settings'; Tw.store.settingsJob = res; Tw.api.load('economy', { resource: res }); },
  },
  template: `
  <div class="page">
    <template v-if="store.jobDetail">
      <template v-if="!detail">
        <div class="grid g4"><tw-skel v-for="i in 4" :key="i" height="7rem"/></div><tw-skel height="20rem"/>
      </template>
      <template v-else>
        <div class="grid g4">
          <tw-kpi :label="t('overview.paid')" icon="coins" :value="fmt.moneyShort(detail.kpi.money.value)" :title="fmt.money(detail.kpi.money.value)" :delta="delta(detail.kpi.money)"/>
          <tw-kpi :label="t('overview.finished')" icon="circle-check" :value="fmt.num(detail.kpi.sessions.value)" :delta="delta(detail.kpi.sessions)"/>
          <tw-kpi :label="t('col.avgDuration')" icon="clock" :value="fmt.duration(detail.kpi.avgDuration.value)"/>
          <tw-kpi :label="t('overview.perHour')" icon="gauge" :value="fmt.moneyShort(detail.kpi.perHour.value)" :title="fmt.money(detail.kpi.perHour.value)" :delta="delta(detail.kpi.perHour)"/>
        </div>
        <div class="card">
          <div class="card-head"><h3>{{ t('jobs.daily') }}</h3></div>
          <div class="card-body">
            <tw-chart v-if="detail.series.labels.length" :config="comboConfig" :deps="detail.series" height="15rem"/>
            <tw-empty v-else icon="activity" :title="t('empty.noData')"/>
          </div>
        </div>
        <div class="card">
          <div class="card-head"><h3>{{ t('jobs.regions') }}</h3><span class="hint">{{ t('jobs.regionsHint') }}</span>
            <div class="right"><button class="btn sm" @click="tune"><tw-icon name="settings"/>{{ t('jobs.tune') }}</button></div>
          </div>
          <div class="card-body tbl-wrap">
            <table class="tbl" v-if="detail.regions.length">
              <thead><tr><th>{{ t('col.region') }}</th><th class="r">{{ t('col.sessions') }}</th><th class="r">{{ t('col.avgPayout') }}</th>
                <th class="r">{{ t('col.avgDuration') }}</th><th>{{ t('col.perHour') }}</th><th class="r">{{ t('col.share') }}</th></tr></thead>
              <tbody>
                <tr v-for="r in detail.regions" :key="r.region">
                  <td><b>{{ r.region || '-' }}</b></td>
                  <td class="r">{{ fmt.num(r.sessions) }}</td>
                  <td class="r money">{{ fmt.money(r.avgMoney) }}</td>
                  <td class="r">{{ fmt.duration(r.avgDuration) }}</td>
                  <td style="min-width:13rem">
                    <div style="display:flex;align-items:center;gap:.6rem">
                      <div class="bar" style="flex:1"><div :style="{ width: (r.perHour / regionMax * 100) + '%', background: generous(r) ? palette.accent : job.color(detail.resource) }"></div></div>
                      <span style="font-variant-numeric:tabular-nums;min-width:4.5rem;text-align:right">{{ fmt.moneyShort(r.perHour) }}</span>
                      <span v-if="generous(r)" class="pill warn" :title="t('jobs.generous', { n: Math.round((r.perHour / regionAverage - 1) * 100) })"><tw-icon name="triangle-alert"/></span>
                    </div>
                  </td>
                  <td class="r muted">{{ detail.kpi.money.value ? Math.round(r.money / detail.kpi.money.value * 100) : 0 }}%</td>
                </tr>
              </tbody>
            </table>
            <tw-empty v-else icon="map-pin" :title="t('empty.noData')"/>
          </div>
        </div>
        <div class="card">
          <div class="card-head"><h3>{{ t('overview.top') }}</h3></div>
          <div class="card-body tbl-wrap">
            <table class="tbl" v-if="detail.top.length">
              <thead><tr><th>{{ t('col.player') }}</th><th class="r">{{ t('col.earned') }}</th><th class="r">{{ t('col.sessions') }}</th><th class="r">{{ t('col.perHour') }}</th></tr></thead>
              <tbody><tr v-for="p in detail.top" :key="p.identifier">
                <td><tw-player :name="p.name" :identifier="p.identifier"/></td><td class="r money">{{ fmt.money(p.money) }}</td>
                <td class="r">{{ fmt.num(p.sessions) }}</td><td class="r">{{ fmt.moneyShort(p.perHour) }}</td></tr></tbody>
            </table>
            <tw-empty v-else icon="users" :title="t('empty.noPlayers')"/>
          </div>
        </div>
      </template>
    </template>

    <template v-else>
      <div v-if="!list" class="grid g3"><tw-skel v-for="i in 3" :key="i" height="12rem"/></div>
      <tw-empty v-else-if="!list.length" icon="briefcase" :title="t('jobs.none')" :text="t('jobs.noneHint')"/>
      <div v-else class="grid g3">
        <div v-for="j in list" :key="j.job" class="card jobcard" :style="{ '--c': job.color(j.job) }" @click="open(j.job)">
          <div class="jobcard-head">
            <tw-job :res="j.job"/>
            <div class="right"><span v-if="j.live" class="pill live"><span class="pulse"></span>{{ t('jobs.lobbies', { n: j.live }) }}</span></div>
          </div>
          <div class="stats">
            <div class="stat"><small>{{ t('col.earned') }}</small><span class="money">{{ fmt.moneyShort(j.money) }}</span>
              <tw-delta v-if="fmt.delta(j.money, j.prev) !== null" :value="fmt.delta(j.money, j.prev)" style="margin-left:.4rem"/></div>
            <div class="stat"><small>{{ t('col.perHour') }}</small><span>{{ fmt.moneyShort(j.perHour) }}</span></div>
            <div class="stat"><small>{{ t('col.sessions') }}</small><span>{{ fmt.num(j.sessions) }}</span></div>
            <div class="stat"><small>{{ t('col.avgDuration') }}</small><span>{{ fmt.duration(j.avgDuration) }}</span></div>
          </div>
          <div class="jobcard-foot">
            <tw-chart v-if="j.spark && j.spark.length > 1" :config="sparkConfig(j)" :deps="j.spark" height="2.6rem" style="flex:1"/>
            <div v-else style="flex:1"></div>
            <button class="btn sm ghost" :title="t('nav.ledger')" @click.stop="goLedger(j.job)"><tw-icon name="scroll-text"/></button>
            <button class="btn sm ghost" :title="t('nav.settings')" @click.stop="goSettings(j.job)"><tw-icon name="settings"/></button>
          </div>
        </div>
      </div>
    </template>
  </div>`,
};
