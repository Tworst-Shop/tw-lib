window.TwPages = window.TwPages || {};
TwPages.ledger = {
  data: () => ({ resource: Tw.store.ledgerJob || '', search: Tw.store.ledgerSearch || '', kind: '', direction: '', period: '7d', rows: [] }),
  computed: {
    d() { return Tw.store.data.ledger; },
    grouped() { return Tw.groupLedger(this.rows); },
    jobs: () => Tw.store.jobs,
    jobOptions() {
      return [{ value: '', label: Tw.t('ledger.allJobs') }]
        .concat(Tw.store.jobs.map(j => ({ value: j, label: Tw.job.name(j) })));
    },
    loading: () => !!Tw.store.loading.ledger,
  },
  watch: {
    d(data) {
      if (!data) return;
      this.rows = data.offset > 0 ? this.rows.concat(data.rows || []) : (data.rows || []);
    },
    search() { clearTimeout(this.debounce); this.debounce = setTimeout(() => this.reload(), 300); },
  },
  mounted() {
    Tw.store.ledgerJob = '';
    Tw.store.ledgerSearch = '';
    if (this.d) this.rows = this.d.rows || [];
  },
  methods: {
    filter() {
      return { resource: this.resource, identifier: this.search.trim(), kind: this.kind, direction: this.direction, period: this.period };
    },
    reload() { Tw.api.load('ledger', Object.assign(this.filter(), { offset: 0 })); },
    more() { Tw.api.load('ledger', Object.assign(this.filter(), { offset: this.rows.length })); },
    set(key, value) { this[key] = value; this.reload(); },
  },
  template: `
  <div class="page">
    <div class="toolbar">
      <tw-select style="width:12rem" :model-value="resource" :options="jobOptions"
        @update:model-value="set('resource', $event)"/>
      <div class="search"><tw-icon name="search"/><input class="input" v-model="search" :placeholder="t('ledger.searchPlayer')"></div>
      <div class="spacer"></div>
      <div class="seg">
        <button v-for="p in ['today', 'yesterday', '7d', '30d', 'all']" :key="p" :class="{ on: period === p }" @click="set('period', p)">{{ t('range.' + p) }}</button>
      </div>
    </div>
    <div class="toolbar">
      <div class="seg">
        <button v-for="k in ['', 'money', 'xp', 'item']" :key="k" :class="{ on: kind === k }" @click="set('kind', k)">{{ t('ledger.kind.' + (k || 'all')) }}</button>
      </div>
      <div class="seg">
        <button v-for="k in ['', 'in', 'out']" :key="k" :class="{ on: direction === k }" @click="set('direction', k)">{{ t('ledger.direction.' + (k || 'all')) }}</button>
      </div>
    </div>
    <div class="card">
      <div class="card-body tbl-wrap">
        <template v-if="!d"><tw-skel v-for="i in 8" :key="i" height="2.4rem" style="margin:.3rem 0"/></template>
        <tw-empty v-else-if="!grouped.length" icon="scroll-text" :title="t('ledger.none')" :text="t('ledger.noneHint')"/>
        <table v-else class="tbl">
          <thead><tr><th>{{ t('col.time') }}</th><th>{{ t('col.player') }}</th><th>{{ t('col.job') }}</th><th>{{ t('col.reason') }}</th>
            <th class="r">{{ t('col.money') }}</th><th class="r">XP</th><th>{{ t('col.items') }}</th></tr></thead>
          <tbody>
            <tr v-for="e in grouped" :key="e.key">
              <td class="muted">{{ fmt.time(e.time) }}</td>
              <td><tw-player :name="e.name" :identifier="e.identifier"/></td>
              <td><tw-job :res="e.job" link/></td>
              <td><span class="pill">{{ t('reason.' + e.reason) === 'reason.' + e.reason ? e.reason : t('reason.' + e.reason) }}</span></td>
              <td class="r">
                <span v-if="e.money" class="money">+{{ fmt.money(e.money) }}</span>
                <span v-if="e.taken" class="neg" style="margin-left:.4rem">-{{ fmt.money(e.taken) }}</span>
                <span v-if="e.account" class="faint" style="margin-left:.4rem;font-size:.75rem">{{ e.account }}</span>
                <span v-if="!e.money && !e.taken" class="faint">-</span>
              </td>
              <td class="r"><span v-if="e.xp" class="xp">{{ fmt.num(e.xp) }}</span><span v-else class="faint">-</span></td>
              <td>
                <span v-for="i in e.items" :key="i.name" class="pill" :class="{ warn: i.out }" style="margin-right:.3rem">{{ i.out ? '-' : '' }}{{ i.count }}× {{ i.name }}</span>
                <span v-if="!e.items.length" class="faint">-</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <div v-if="d && d.hasMore" style="display:flex;justify-content:center">
      <button class="btn" @click="more" :disabled="loading">{{ t('ledger.more') }}</button>
    </div>
  </div>`,
};
