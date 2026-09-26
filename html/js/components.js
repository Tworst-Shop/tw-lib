(function () {
  const { store, t, fmt, job, initials, api } = Tw;

  window.TwComponents = {
    'tw-icon': {
      props: { name: String },
      computed: { url() { const u = (window.TwIcons || {})[this.name]; return u ? 'url("' + u + '")' : 'none'; } },
      template: '<i class="ic" :style="{ webkitMaskImage: url, maskImage: url }"></i>',
    },

    'tw-select': {
      props: { modelValue: { type: [String, Number, Boolean], default: '' }, options: { type: Array, default: () => [] },
        placeholder: String, changed: Boolean, disabled: Boolean },
      emits: ['update:modelValue'],
      data: () => ({ open: false, active: -1, style: {} }),
      computed: {
        items() {
          return (this.options || []).map(o => (o && typeof o === 'object'
            ? { value: o.value, label: String(o.label) }
            : { value: o, label: String(o) }));
        },
        currentLabel() {
          const found = this.items.find(i => i.value === this.modelValue);
          return found ? found.label : (this.placeholder || '');
        },
      },
      methods: {
        toggle() {
          if (this.disabled) return;
          if (this.open) { this.open = false; return; }
          this.open = true;
          this.active = this.items.findIndex(i => i.value === this.modelValue);
          this.$nextTick(() => this.place());
        },
        place() {
          const button = this.$refs.button;
          const list = this.$refs.list;
          if (!button || !list) return;
          const box = button.getBoundingClientRect();
          const height = list.offsetHeight;
          const below = window.innerHeight - box.bottom - 8;
          const top = height > below && box.top > below ? box.top - height - 6 : box.bottom + 6;
          this.style = { top: Math.max(8, top) + 'px', left: box.left + 'px', minWidth: box.width + 'px' };
        },
        pick(item) {
          this.open = false;
          if (item.value !== this.modelValue) this.$emit('update:modelValue', item.value);
        },
        move(step) {
          if (!this.open) { this.toggle(); return; }
          const count = this.items.length;
          if (!count) return;
          this.active = (this.active + step + count) % count;
        },
        keys(event) {
          if (event.key === 'Escape') { this.open = false; return; }
          if (event.key === 'ArrowDown') { event.preventDefault(); this.move(1); return; }
          if (event.key === 'ArrowUp') { event.preventDefault(); this.move(-1); return; }
          if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            if (this.open && this.items[this.active]) this.pick(this.items[this.active]);
            else this.toggle();
          }
        },
        away(event) {
          if (!this.open) return;
          const button = this.$refs.button;
          const list = this.$refs.list;
          if ((button && button.contains(event.target)) || (list && list.contains(event.target))) return;
          this.open = false;
        },
        reflow(event) {
          if (!this.open) return;
          const list = this.$refs.list;
          if (event && list && event.target && list === event.target) return;
          if (event && list && event.target && event.target.nodeType === 1 && list.contains(event.target)) return;
          const button = this.$refs.button;
          const box = button && button.getBoundingClientRect();
          if (box && (box.bottom < 0 || box.top > window.innerHeight)) { this.open = false; return; }
          this.place();
        },
      },
      mounted() {
        document.addEventListener('mousedown', this.away, true);
        window.addEventListener('scroll', this.reflow, true);
        window.addEventListener('resize', this.reflow);
      },
      beforeUnmount() {
        document.removeEventListener('mousedown', this.away, true);
        window.removeEventListener('scroll', this.reflow, true);
        window.removeEventListener('resize', this.reflow);
      },
      template: `
        <div class="tw-select" :class="{ open, changed, disabled }">
          <button ref="button" type="button" class="tw-select-btn" :disabled="disabled" @click="toggle" @keydown="keys">
            <span class="tw-select-label">{{ currentLabel }}</span>
            <tw-icon name="chevron-right"/>
          </button>
          <Teleport to="#menu">
            <Transition name="drop">
              <div v-if="open" ref="list" class="tw-drop" :style="style">
                <button v-for="(item, i) in items" :key="String(item.value)" type="button" class="tw-drop-item"
                  :class="{ on: item.value === modelValue, active: i === active }"
                  @mouseenter="active = i" @click="pick(item)">
                  <span>{{ item.label }}</span>
                  <tw-icon v-if="item.value === modelValue" name="check"/>
                </button>
              </div>
            </Transition>
          </Teleport>
        </div>`,
    },

    'tw-chart': {
      props: { config: Function, deps: null, height: { type: String, default: '17rem' } },
      template: '<div class="chart-box" :style="{ height }"><canvas ref="canvas"></canvas></div>',
      mounted() { this.draw(); },
      beforeUnmount() { if (this._chart) this._chart.destroy(); },
      watch: { deps: { deep: true, handler() { this.draw(); } } },
      methods: {
        draw() {
          if (this._chart) this._chart.destroy();
          this._chart = new Chart(this.$refs.canvas, this.config());
        },
      },
    },

    'tw-delta': {
      props: { value: Number },
      computed: {
        cls() { return this.value > 0 ? 'up' : this.value < 0 ? 'down' : 'flat'; },
        icon() { return this.value < 0 ? 'arrow-down-right' : 'arrow-up-right'; },
      },
      template: '<span class="delta" :class="cls" :title="t(\'overview.vsPrevious\')"><tw-icon v-if="value" :name="icon"/>{{ Math.abs(value) }}%</span>',
    },

    'tw-kpi': {
      props: { label: String, icon: String, value: String, title: String, delta: { type: Number, default: null },
        note: String, spark: Array, color: { type: String, default: Tw.palette.money } },
      computed: { sparkConfig() { return () => TwCharts.spark(this.spark, this.color); } },
      template: `
        <div class="card kpi">
          <div class="kpi-label"><tw-icon :name="icon"/>{{ label }}</div>
          <div class="kpi-row">
            <div class="kpi-value" :title="title">{{ value }}</div>
            <tw-delta v-if="delta !== null && delta !== undefined" :value="delta"/>
          </div>
          <div class="kpi-note" v-if="note">{{ note }}</div>
          <tw-chart v-if="spark && spark.length > 1" :config="sparkConfig" :deps="spark" height="2.6rem"/>
        </div>`,
    },

    'tw-job': {
      props: { res: String, link: Boolean },
      computed: { name() { return job.name(this.res); }, color() { return job.color(this.res); } },
      methods: {
        go(e) {
          if (!this.link) return;
          e.stopPropagation();
          store.page = 'jobs';
          store.jobDetail = this.res;
          api.load('job', { resource: this.res });
        },
      },
      template: '<span class="job" :class="{ link }" @click="go" :style="link ? \'cursor:pointer\' : \'\'"><i :style="{ background: color }"></i>{{ name }}</span>',
    },

    'tw-player': {
      props: { name: String, identifier: String },
      methods: {
        open(e) {
          e.stopPropagation();
          store.drawer = this.identifier;
          api.load('player', { identifier: this.identifier });
        },
      },
      template: '<span class="name-cell" style="cursor:pointer" @click="open"><span>{{ name || identifier }}</span><small v-if="name">{{ identifier }}</small></span>',
    },

    'tw-avatar': {
      props: { name: String, color: String },
      computed: { letters() { return initials(this.name); } },
      template: '<span class="avatar" :style="{ \'--c\': color || palette.muted }">{{ letters }}</span>',
    },

    'tw-empty': {
      props: { icon: { type: String, default: 'inbox' }, title: String, text: String },
      template: '<div class="empty"><tw-icon :name="icon"/><b>{{ title }}</b><small v-if="text">{{ text }}</small></div>',
    },

    'tw-skel': {
      props: { height: { type: String, default: '8rem' } },
      template: '<div class="skel" :style="{ height }"></div>',
    },
  };
})();
