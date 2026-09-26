window.TwPages = window.TwPages || {};
TwPages.live = {
  mounted() { this.timer = setInterval(() => Tw.api.load('live'), 10000); },
  unmounted() { clearInterval(this.timer); },
  computed: {
    d() { return Tw.store.data.live; },
    lobbies() { return (this.d && this.d.lobbies) || []; },
    players() { return this.lobbies.reduce((s, l) => s + (l.members || []).length, 0); },
  },
  methods: {
    elapsed(l) { return l.seconds + Math.max(0, (Tw.store.now - this.d._at) / 1000); },
    openPlayer(m) { Tw.store.drawer = m.identifier; Tw.api.load('player', { identifier: m.identifier }); },
    teleport(l) { Tw.api.action('teleport', { resource: l.job, lobby: l.id }); },
    async endJob(l) {
      if (await Tw.confirm(Tw.t('live.endTitle'), Tw.t('live.endText', { n: (l.members || []).length }), true)) {
        Tw.api.action('endJob', { resource: l.job, lobby: l.id });
      }
    },
    async closeLobby(l) {
      if (await Tw.confirm(Tw.t('live.closeTitle'), Tw.t('live.closeText', { n: (l.members || []).length }), true)) {
        Tw.api.action('closeLobby', { resource: l.job, lobby: l.id });
      }
    },
  },
  template: `
  <div class="page">
    <div v-if="!d" class="grid g3"><tw-skel v-for="i in 3" :key="i" height="11rem"/></div>
    <template v-else>
      <div class="toolbar">
        <span class="pill live" v-if="lobbies.length"><span class="pulse"></span>{{ t('live.summary', { lobbies: lobbies.length, players }) }}</span>
        <span class="faint" style="font-size:.8rem">{{ t('live.autoRefresh') }}</span>
      </div>
      <tw-empty v-if="!lobbies.length" icon="radio" :title="t('live.empty')" :text="t('live.emptyHint')"/>
      <div v-else class="grid g3">
        <div v-for="l in lobbies" :key="l.job + l.id" class="card lobby" :style="{ '--c': job.color(l.job) }">
          <div class="lobby-head">
            <tw-job :res="l.job" link/>
            <span class="muted" v-if="l.region">· {{ l.region }}</span>
            <span class="timer" :class="{ faint: !l.started }">{{ fmt.clock(elapsed(l)) }}</span>
          </div>
          <div style="display:flex;gap:.45rem;align-items:center">
            <span class="pill" :class="{ live: l.started }"><span v-if="l.started" class="pulse"></span>{{ l.started ? t('live.working') : t('live.waiting') }}</span>
            <span class="pill"><tw-icon name="users"/>{{ (l.members || []).length }}<template v-if="l.max"> / {{ l.max }}</template></span>
          </div>
          <div class="people">
            <span v-for="m in l.members" :key="m.identifier" class="person" style="cursor:pointer" @click="openPlayer(m)">
              <tw-avatar :name="m.name || m.identifier" :color="job.color(l.job)"/>{{ m.name || m.identifier }}
              <tw-icon v-if="l.owner && m.identifier === l.owner.identifier" name="sparkles" style="width:.8rem;height:.8rem;color:#58a8f5" :title="t('live.owner')"/>
            </span>
          </div>
          <div class="lobby-actions">
            <button class="btn sm" @click="teleport(l)"><tw-icon name="map-pin"/>{{ t('live.teleport') }}</button>
            <button class="btn sm" v-if="l.started" @click="endJob(l)"><tw-icon name="circle-check"/>{{ t('live.end') }}</button>
            <button class="btn sm danger" @click="closeLobby(l)"><tw-icon name="x"/>{{ t('live.close') }}</button>
          </div>
        </div>
      </div>
      <div v-if="d.quiet && d.quiet.length" class="banner"><tw-icon name="triangle-alert"/>{{ t('live.quiet', { jobs: d.quiet.map(job.name).join(', ') }) }}</div>
    </template>
  </div>`,
};
