(function () {
  const LIB = window.TW_LIB || 'nui://tw-lib/html/';
  window.TW_LIB_JOB = LIB + 'job/';
  const preview = typeof GetParentResourceName !== 'function';

  document.write('<link rel="stylesheet" href="' + LIB + 'job/job.css">');

  const load = src => new Promise((resolve, reject) => {
    const s = document.createElement('script');
    s.src = src;
    s.onload = resolve;
    s.onerror = () => reject(new Error('tw-lib job UI: could not load ' + src));
    document.head.appendChild(s);
  });

  window.addEventListener('DOMContentLoaded', async () => {
    try {
      for (const src of [LIB + 'vendor/vue.global.prod.js', LIB + 'job/parts.js', LIB + 'job/app.js']) await load(src);
      await load('js/job.js').catch(() => {});
      TwJob.mount('#app');
      if (preview) await load(LIB + 'job/mock.js');
    } catch (err) {
      console.error(err.message);
    }
  });
})();
