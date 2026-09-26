window.TwPages = window.TwPages || {};
TwPages.settings = {
  data: () => ({ justSaved: false }),
  computed: {
    store: () => Tw.store,
    d() { const d = Tw.store.data.economy; return d && d.resource === Tw.store.settingsJob ? d : null; },
    rows() { return (this.d && this.d.settings) || []; },
    general() { return this.rows.filter(r => !r.groupKey); },
    lists() {
      const lists = [], byKey = {};
      for (const row of this.rows.filter(r => r.groupKey)) {
        let list = byKey[row.groupKey];
        if (!list) { list = byKey[row.groupKey] = { key: row.groupKey, columns: [], entries: [], byIndex: {} }; lists.push(list); }
        if (!list.columns.some(c => c.key === row.key)) list.columns.push({ key: row.key, order: row.order });
        let entry = list.byIndex[row.groupIndex];
        if (!entry) { entry = list.byIndex[row.groupIndex] = { index: row.groupIndex, name: row.group, cells: {} }; list.entries.push(entry); }
        entry.cells[row.key] = row;
      }
      for (const list of lists) {
        list.columns.sort((a, b) => a.order - b.order);
        list.entries.sort((a, b) => a.index - b.index);
      }
      return lists;
    },
    dirty() { return Object.keys(Tw.store.pending).length + Object.keys(Tw.store.resets).length; },
  },
  watch: {
    d(data) {
      if (!data || data.saved === undefined) return;
      Tw.store.pending = {};
      Tw.store.resets = {};
      this.justSaved = !data.errors || !data.errors.length;
    },
  },
  mounted() {
    if (!Tw.store.settingsJob && Tw.store.jobs.length) Tw.store.settingsJob = Tw.store.jobs[0];
    if (Tw.store.settingsJob && !this.d) Tw.api.load('economy', { resource: Tw.store.settingsJob });
  },
  methods: {
    label(key) { return Tw.t('economy.fields.' + key + '.label'); },
    choice(value) { return Tw.t('economy.choices.' + value); },
    shown(row, value) { return row.type === 'boolean' ? Tw.t('common.' + value) : row.type === 'choice' ? this.choice(value) : Tw.fmt.num(value); },
    jobName(res) { return res === 'tw-lib' ? Tw.t('settings.allJobs') : Tw.job.name(res); },
    desc(key) { return Tw.t('economy.fields.' + key + '.desc'); },
    current(row) {
      if (row.path in Tw.store.pending) return Tw.store.pending[row.path];
      if (Tw.store.resets[row.path]) return row.default;
      return row.value;
    },
    isCustom(row) { const v = this.current(row); return row.default !== undefined && v !== row.default; },
    isEdited(row) { return row.path in Tw.store.pending || !!Tw.store.resets[row.path]; },
    edit(row, raw) {
      const value = row.type === 'boolean' ? !!raw : row.type === 'choice' ? String(raw) : Number(raw);
      if (row.type === 'number' && (raw === '' || !isFinite(value))) return;
      delete Tw.store.resets[row.path];
      if (value === row.value) delete Tw.store.pending[row.path];
      else Tw.store.pending[row.path] = value;
      this.justSaved = false;
    },
    reset(row) {
      delete Tw.store.pending[row.path];
      if (row.changed) Tw.store.resets[row.path] = true;
      this.justSaved = false;
    },
    undo() { Tw.store.pending = {}; Tw.store.resets = {}; },
    save() {
      const changes = Object.keys(Tw.store.pending).map(path => ({ path, value: Tw.store.pending[path] }));
      Tw.api.saveSettings(Tw.store.settingsJob, changes, Object.keys(Tw.store.resets));
    },
    async pick(res) {
      if (res === Tw.store.settingsJob) return;
      if (this.dirty && !(await Tw.confirm(Tw.t('settings.discardTitle'), Tw.t('settings.discardText', { n: this.dirty })))) return;
      this.undo();
      this.justSaved = false;
      Tw.store.settingsJob = res;
      Tw.api.load('economy', { resource: res });
    },
    async restart() {
      const n = this.d.lobbies || 0;
      const text = n ? Tw.t('settings.restartLobbies', { n }) : Tw.t('settings.restartNoLobbies');
      if (!(await Tw.confirm(Tw.t('settings.restartTitle', { job: this.jobName(Tw.store.settingsJob) }), text, n > 0))) return;
      this.justSaved = false;
      Tw.api.action('restart', { resource: Tw.store.settingsJob });
    },
    perHour(entry) { const s = this.d.regionStats || {}; return s[entry.index]; },
  },
  template: `
  <div class="page" style="min-height:100%">
    <div class="jobchips">
      <button class="jobchip" :class="{ on: store.settingsJob === 'tw-lib' }" style="--c:#58a8f5" @click="pick('tw-lib')">
        <span class="job"><i style="background:#58a8f5"></i>{{ t('settings.allJobs') }}</span>
      </button>
      <button v-for="res in store.jobs" :key="res" class="jobchip" :class="{ on: res === store.settingsJob }" :style="{ '--c': job.color(res) }" @click="pick(res)">
        <tw-job :res="res"/>
        <span class="count" v-if="d && res === store.settingsJob && rows.filter(r => r.changed).length">{{ rows.filter(r => r.changed).length }}</span>
      </button>
    </div>
      <div style="display:flex;flex-direction:column;gap:1rem;min-width:0">
        <template v-if="!d"><tw-skel height="9rem"/><tw-skel height="16rem"/></template>
        <template v-else>
          <div v-if="d.errors && d.errors.length" class="banner error"><tw-icon name="triangle-alert"/>
            {{ t('settings.errors', { n: d.errors.length }) }} {{ d.errors.map(e => label(e.key || e.path)).join(', ') }}</div>
          <tw-empty v-if="!rows.length" icon="settings" :title="t('economy.empty')"/>

          <div class="card" v-if="general.length">
            <div class="card-head"><h3>{{ store.settingsJob === 'tw-lib' ? t('settings.allJobs') : t('economy.general') }}</h3></div>
            <div class="card-body grid g2">
              <div v-for="row in general" :key="row.path" class="field">
                <div class="field-text"><b>{{ label(row.key) }}</b><small>{{ desc(row.key) }}</small></div>
                <div class="cell">
                  <div class="cell-row">
                    <button class="reset" :class="{ hidden: !isCustom(row) }" :title="t('settings.reset')" @click="reset(row)"><tw-icon name="rotate-ccw"/></button>
                    <button v-if="row.type === 'boolean'" class="toggle" :class="{ on: current(row) }" @click="edit(row, !current(row))"></button>
                    <tw-select v-else-if="row.type === 'choice'" style="width:13rem;max-width:100%"
                      :model-value="current(row)" :options="row.options.map(o => ({ value: o, label: choice(o) }))"
                      :changed="isEdited(row)" @update:model-value="edit(row, $event)"/>
                    <input v-else class="input num" :class="{ changed: isEdited(row) }" type="number" :value="current(row)" @input="edit(row, $event.target.value)">
                  </div>
                  <small v-if="isCustom(row)">{{ t('settings.default', { v: shown(row, row.default) }) }}</small>
                </div>
              </div>
            </div>
          </div>

          <div class="card" v-for="list in lists" :key="list.key">
            <div class="card-head"><h3>{{ t('economy.groups.' + list.key) }}</h3><span class="hint">{{ t('settings.regionsHint') }}</span></div>
            <div class="card-body tbl-wrap">
              <table class="tbl regions">
                <thead><tr>
                  <th>{{ t('col.region') }}</th>
                  <template v-for="c in list.columns" :key="c.key">
                    <th class="r"><span class="th-help" :title="desc(c.key)">{{ label(c.key) }}</span></th>
                    <th v-if="c.key === 'money'" class="r"><span class="th-help" :title="t('settings.perHourHint')">{{ t('col.perHour7d') }}</span></th>
                  </template>
                </tr></thead>
                <tbody>
                  <tr v-for="e in list.entries" :key="e.index">
                    <td><b>{{ e.name }}</b></td>
                    <template v-for="c in list.columns" :key="c.key">
                      <td class="r">
                        <div class="cell" v-if="e.cells[c.key]">
                          <div class="cell-row">
                            <button class="reset" :class="{ hidden: !isCustom(e.cells[c.key]) }" :title="t('settings.reset')" @click="reset(e.cells[c.key])"><tw-icon name="rotate-ccw"/></button>
                            <button v-if="e.cells[c.key].type === 'boolean'" class="toggle" :class="{ on: current(e.cells[c.key]) }" @click="edit(e.cells[c.key], !current(e.cells[c.key]))"></button>
                            <input v-else class="input num" :class="{ changed: isEdited(e.cells[c.key]) }" type="number"
                              :value="current(e.cells[c.key])" @input="edit(e.cells[c.key], $event.target.value)">
                          </div>
                          <small v-if="isCustom(e.cells[c.key])">{{ t('settings.default', { v: fmt.num(e.cells[c.key].default) }) }}</small>
                        </div>
                        <span v-else class="faint">-</span>
                      </td>
                      <td v-if="c.key === 'money'" class="r muted">{{ perHour(e) ? fmt.moneyShort(perHour(e)) : '-' }}</td>
                    </template>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </template>
      </div>

    <div v-if="dirty" class="savebar dirty">
      <div class="msg"><tw-icon name="circle-check"/>{{ t('settings.pending', { n: dirty }) }}</div>
      <div class="right">
        <button class="btn ghost" @click="undo"><tw-icon name="rotate-ccw"/>{{ t('settings.undo') }}</button>
        <button class="btn primary" @click="save"><tw-icon name="check"/>{{ t('settings.save') }}</button>
      </div>
    </div>
    <div v-else-if="justSaved && d && d.restartNeeded" class="savebar ok">
      <div class="msg"><tw-icon name="circle-check"/>{{ t('settings.saved') }}</div>
      <div class="right">
        <span class="faint" v-if="d.lobbies" style="align-self:center;font-size:.82rem">{{ t('settings.activeLobbies', { n: d.lobbies }) }}</span>
        <button class="btn" @click="restart"><tw-icon name="power"/>{{ t('settings.restartNow') }}</button>
      </div>
    </div>
  </div>`,
};
