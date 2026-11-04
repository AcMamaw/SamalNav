const CACHE_PREFIX = 'samal-nav-shell-';
const CACHE_NAME = `${CACHE_PREFIX}v1`;
const SHELL_ASSETS = [
  './',
  'index.html',
  'manifest.json',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'version.json',
];

function isFlutterStaticAsset(url, request) {
  return request.destination !== '' ||
    url.pathname.includes('/assets/') ||
    url.pathname.includes('/canvaskit/') ||
    url.pathname.endsWith('/main.dart.js') ||
    url.pathname.endsWith('/flutter.js') ||
    url.pathname.endsWith('/flutter_bootstrap.js') ||
    url.pathname.endsWith('/version.json') ||
    url.pathname.endsWith('/manifest.json');
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await Promise.all(SHELL_ASSETS.map(async (url) => {
      try {
        await cache.add(new Request(new URL(url, self.registration.scope), { cache: 'reload' }));
      } catch (error) {
        console.warn(`Could not precache shell asset ${url}`, error);
      }
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const cacheNames = await caches.keys();
    await Promise.all(cacheNames
      .filter((name) => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME)
      .map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;

  event.respondWith((async () => {
    const cached = await caches.match(request);
    if (request.mode !== 'navigate' && cached) return cached;

    try {
      const response = await fetch(request);
      if (response.ok && response.type === 'basic' && isFlutterStaticAsset(url, request)) {
        const cache = await caches.open(CACHE_NAME);
        await cache.put(request, response.clone());
      }
      return response;
    } catch (error) {
      if (cached) return cached;
      if (request.mode === 'navigate') {
        const shell = await caches.match('./');
        if (shell) return shell;
      }
      throw error;
    }
  })());
});
