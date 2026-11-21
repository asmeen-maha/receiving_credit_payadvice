{{flutter_js}}
{{flutter_build_config}}

// Internal app: nothing should be fetched from the internet.
_flutter.loader.load({
  // Kept so the generated (empty, with --pwa-strategy=none) service worker
  // replaces any old caching one already registered in users' browsers.
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  config: {
    // CanvasKit from our own server (build/web/canvaskit/), not www.gstatic.com,
    // even if a build forgets --no-web-resources-cdn.
    canvasKitBaseUrl: "canvaskit/",
    // Fallback fonts for characters our bundled fonts lack (e.g. a Chinese
    // agent name from the API) would be downloaded from fonts.gstatic.com.
    // Point them at our server instead; the folder is intentionally absent,
    // so such characters show as boxes rather than leaking requests outside.
    fontFallbackBaseUrl: "assets/fallback_fonts/",
  },
});
