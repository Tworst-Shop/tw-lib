(function () {
  const { store, t, fmt, api } = Tw;

  const NAV = [
    { id: 'overview', icon: 'layout-dashboard', tab: 'overview' },
    { id: 'jobs', icon: 'briefcase', tab: 'jobs' },
    { id: 'live', icon: 'radio', tab: 'live' },
    { id: 'players', icon: 'users', tab: 'players' },
    { id: 'ledger', icon: 'scroll-text', tab: 'ledger' },
    { id: 'settings', icon: 'settings', tab: 'economy' },
  ];
  const RANGED = ['overview', 'jobs', 'players'];

  const app = Vue.createApp({
    computed: {
      store: () => store,
      nav: () => NAV,
      ranged() { return RANGED.includes(store.page); },
      title() { return store.page === 'jobs' && store.jobDetail ? Tw.job.name(store.jobDetail) : t('nav.' + store.page); },
      subtitle() { return store.page === 'jobs' && store.jobDetail ? t('jobs.detailSub') : t('sub.' + store.page); },
      busy() { return Object.values(store.loading).some(Boolean); },
      dirtySettings() { return Object.keys(store.pending).length + Object.keys(store.resets).length > 0; },
      activeIndex() { return NAV.findIndex(n => n.id === store.page); },
    },
    methods: {
      go(item) {
        store.drawer = null;
        if (item.id === 'jobs') store.jobDetail = null;
        store.page = item.id;
        this.refresh();
      },
      back() { store.jobDetail = null; api.load('jobs'); },
      setRange(range) { store.range = range; this.refresh(); },
      refresh() {
        const page = store.page;
        if (page === 'jobs' && store.jobDetail) return api.load('job', { resource: store.jobDetail, fresh: true });
        if (page === 'settings') return store.settingsJob ? api.load('economy', { resource: store.settingsJob }) : null;
        if (page === 'ledger') return api.load('ledger', { offset: 0 });
        api.load(NAV.find(n => n.id === page).tab, { fresh: true });
      },
      answer(ok) { const c = store.confirm; store.confirm = null; if (c) c.resolve(ok); },
      close() {
        if (store.confirm) return this.answer(false);
        if (store.drawer) { store.drawer = null; return; }
        store.open = false;
        api.close();
      },
    },
    mounted() {
      document.addEventListener('keydown', e => { if (e.key === 'Escape' && store.open) this.close(); });
    },
    template: `
    <div id="menu" :class="{ open: store.open }">
      <div class="shell">
        <aside class="side">
          <div class="brand">
            <div class="brand-mark"><tw-icon name="coins"/></div>
            <div><div class="brand-name">tw-lib</div><div class="brand-sub">{{ t('brand.sub') }}</div></div>
          </div>
          <nav class="nav" :style="{ '--active': activeIndex }">
            <span class="nav-marker"></span>
            <button v-for="item in nav" :key="item.id" class="nav-item" :class="{ active: store.page === item.id }" @click="go(item)">
              <span class="nav-icon"><tw-icon :name="item.icon"/></span>
              <span class="nav-label">{{ t('nav.' + item.id) }}</span>
              <span v-if="item.id === 'live' && store.liveCount" class="nav-badge">{{ store.liveCount }}</span>
              <span v-if="item.id === 'settings' && dirtySettings" class="nav-dot"></span>
            </button>
          </nav>
          <div class="side-foot">
            <div><b>{{ store.jobs.length }}</b> {{ t('brand.jobsRunning') }}</div>
            <div>tw-lib {{ store.data.overview && store.data.overview.version || '' }}</div>
          </div>
        </aside>

        <section class="main">
          <header class="top">
            <button v-if="store.page === 'jobs' && store.jobDetail" class="back" @click="back"><tw-icon name="chevron-left"/></button>
            <div class="top-title"><h1>{{ title }}</h1><span class="sub">{{ subtitle }}</span></div>
            <div class="top-actions">
              <div v-if="ranged" class="seg">
                <button v-for="r in ['today', '7d', '30d', 'all']" :key="r" :class="{ on: store.range === r }" @click="setRange(r)">{{ t('range.' + r) }}</button>
              </div>
              <span class="updated" v-if="store.updatedAt">{{ fmt.ago(store.updatedAt) }}</span>
              <button class="icon-btn" :class="{ spin: busy }" :title="t('common.refresh')" @click="refresh"><tw-icon name="refresh-cw"/></button>
              <button class="icon-btn close" :title="t('common.close')" @click="close"><tw-icon name="x"/></button>
            </div>
          </header>
          <main class="content">
            <Transition name="page" mode="out-in">
              <component :is="'page-' + store.page" :key="store.page"/>
            </Transition>
          </main>
        </section>

        <tw-drawer/>

        <Transition name="modal" :duration="{ enter: 260, leave: 160 }">
        <div v-if="store.confirm" class="modal-back" @click.self="answer(false)">
          <div class="modal">
            <h3>{{ store.confirm.title }}</h3>
            <p>{{ store.confirm.text }}</p>
            <div class="actions">
              <button class="btn ghost" @click="answer(false)">{{ t('common.cancel') }}</button>
              <button class="btn" :class="store.confirm.danger ? 'danger' : 'primary'" @click="answer(true)">{{ t('common.confirm') }}</button>
            </div>
          </div>
        </div>
        </Transition>
        <Transition name="toast">
          <div v-if="store.toast" class="toast" :class="{ error: store.toast.error }">
            <tw-icon :name="store.toast.error ? 'triangle-alert' : 'circle-check'"/>{{ store.toast.text }}
          </div>
        </Transition>
      </div>
    </div>`,
  });

  Object.assign(app.config.globalProperties, { t, fmt, job: Tw.job, palette: Tw.palette });
  for (const name in TwComponents) app.component(name, TwComponents[name]);
  for (const name in TwPages) app.component('page-' + name, TwPages[name]);

  app.mount('#twlib-app');
  TwCharts.theme();
})();
