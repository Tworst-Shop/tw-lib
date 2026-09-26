(function () {
  const { fmt } = Tw;

  function alpha(color, a) {
    if (color.startsWith('hsl(')) return color.replace('hsl(', 'hsla(').replace(')', ', ' + a + ')');
    const hex = color.replace('#', '');
    const n = parseInt(hex.length === 3 ? hex.split('').map(c => c + c).join('') : hex, 16);
    return 'rgba(' + (n >> 16 & 255) + ',' + (n >> 8 & 255) + ',' + (n & 255) + ',' + a + ')';
  }

  function theme() {
    const menu = document.getElementById('menu');
    const px = (menu && parseFloat(getComputedStyle(menu).fontSize)) || 14;
    const d = Chart.defaults;
    d.color = 'rgba(238,241,246,.58)';
    d.borderColor = 'rgba(202,217,242,.09)';
    d.font.family = "Gilroy, 'Inter', 'Segoe UI', sans-serif";
    d.font.size = Math.round(px * 0.8);
    d.maintainAspectRatio = false;
    d.animation.duration = 480;
    d.animation.easing = 'easeOutQuart';
    d.animations = { colors: false };
    d.plugins.legend.display = false;
    Object.assign(d.plugins.tooltip, {
      backgroundColor: '#272b33', borderWidth: 0, titleColor: '#eef1f6',
      bodyColor: 'rgba(238,241,246,.78)', padding: Math.round(px * 0.75), cornerRadius: 10, boxPadding: 4, usePointStyle: true,
      titleFont: { weight: '700' },
    });
  }

  const fade = (color, top) => ctx => {
    const area = ctx.chart.chartArea;
    if (!area) return 'transparent';
    const g = ctx.chart.ctx.createLinearGradient(0, area.top, 0, area.bottom);
    g.addColorStop(0, alpha(color, top));
    g.addColorStop(1, alpha(color, 0));
    return g;
  };

  const grid = { color: 'rgba(202,217,242,.06)', drawTicks: false };
  const noAxis = { display: false };

  window.TwCharts = {
    alpha, theme,

    spark: (values, color) => ({
      type: 'line',
      data: { labels: values.map((_, i) => i), datasets: [{ data: values, borderColor: color, borderWidth: 2, tension: .35,
        pointRadius: 0, fill: true, backgroundColor: fade(color, .28) }] },
      options: { plugins: { tooltip: { enabled: false } }, scales: { x: noAxis, y: Object.assign({}, noAxis, { beginAtZero: true }) },
        layout: { padding: { top: 2, bottom: 0 } }, events: [] },
    }),

    area: (labels, series, format) => ({
      type: 'line',
      data: { labels, datasets: series.map(s => ({ label: s.label, data: s.data, borderColor: s.color, borderWidth: 2,
        backgroundColor: alpha(s.color, .16), pointBackgroundColor: s.color, fill: true, tension: .35, pointRadius: 0, pointHoverRadius: 4,
        pointHoverBackgroundColor: s.color, pointHoverBorderColor: '#1f2228', pointHoverBorderWidth: 2 })) },
      options: {
        interaction: { mode: 'index', intersect: false },
        plugins: { tooltip: { callbacks: { label: c => ' ' + c.dataset.label + '  ' + format(c.parsed.y) } } },
        scales: {
          x: { grid: { display: false }, border: { display: false }, ticks: { maxRotation: 0, autoSkipPadding: 18 } },
          y: { stacked: true, beginAtZero: true, grid, border: { display: false }, ticks: { padding: 8, maxTicksLimit: 5, callback: v => fmt.short(v) } },
        },
      },
    }),

    doughnut: (items, format) => ({
      type: 'doughnut',
      data: { labels: items.map(i => i.label), datasets: [{ data: items.map(i => i.value), backgroundColor: items.map(i => i.color),
        borderColor: '#1f2228', borderWidth: 3, hoverOffset: 6 }] },
      options: { cutout: '72%', plugins: { tooltip: { callbacks: { label: c => ' ' + c.label + '  ' + format(c.parsed) } } } },
    }),

    combo: (labels, bars, line, color, format) => ({
      type: 'bar',
      data: { labels, datasets: [
        { type: 'bar', label: bars.label, data: bars.data, backgroundColor: alpha(color, .55), hoverBackgroundColor: color,
          borderRadius: 5, maxBarThickness: 28, yAxisID: 'y' },
        { type: 'line', label: line.label, data: line.data, borderColor: 'rgba(238,241,246,.85)', pointBackgroundColor: '#eef1f6', borderWidth: 2, tension: .35, pointRadius: 0,
          pointHoverRadius: 4, yAxisID: 'y1' },
      ] },
      options: {
        interaction: { mode: 'index', intersect: false },
        plugins: { tooltip: { callbacks: { label: c => ' ' + c.dataset.label + '  ' + (c.datasetIndex === 0 ? format(c.parsed.y) : fmt.num(c.parsed.y)) } } },
        scales: {
          x: { grid: { display: false }, border: { display: false }, ticks: { maxRotation: 0, autoSkipPadding: 18 } },
          y: { beginAtZero: true, grid, border: { display: false }, ticks: { padding: 8, maxTicksLimit: 5, callback: v => fmt.short(v) } },
          y1: { beginAtZero: true, position: 'right', grid: { display: false }, border: { display: false }, ticks: { padding: 8, maxTicksLimit: 5, precision: 0 } },
        },
      },
    }),

    hbars: (items, format) => ({
      type: 'bar',
      data: { labels: items.map(i => i.label), datasets: [{ data: items.map(i => i.value), backgroundColor: items.map(i => alpha(i.color, .7)),
        hoverBackgroundColor: items.map(i => i.color), borderRadius: 5, maxBarThickness: 22 }] },
      options: { indexAxis: 'y', plugins: { tooltip: { callbacks: { label: c => ' ' + format(c.parsed.x) } } },
        scales: { x: { beginAtZero: true, grid, border: { display: false }, ticks: { maxTicksLimit: 4, callback: v => fmt.short(v) } },
          y: { grid: { display: false }, border: { display: false } } } },
    }),
  };
})();
