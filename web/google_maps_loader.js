// The key comes from Flutter's build configuration, never from this file.
(() => {
  let pending;
  window.loadSerenoGoogleMaps = (apiKey) => {
    if (window.google?.maps?.Map) return Promise.resolve();
    if (pending) return pending;
    pending = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      const timer = setTimeout(fail, 20000);
      function fail() {
        clearTimeout(timer);
        script.remove();
        pending = undefined;
        reject(new Error('No se pudo cargar Google Maps.'));
      }
      window.serenoMapsReady = () => {
        clearTimeout(timer);
        resolve();
      };
      window.gm_authFailure = fail;
      const parameters = new URLSearchParams({
        key: apiKey,
        callback: 'serenoMapsReady',
        loading: 'async',
        v: 'quarterly',
        language: 'es',
      });
      script.src = `https://maps.googleapis.com/maps/api/js?${parameters}`;
      script.async = true;
      script.onerror = fail;
      document.head.append(script);
    });
    return pending;
  };
})();
