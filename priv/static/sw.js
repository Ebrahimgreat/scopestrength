

const VERSION = "v1";
const ASSETS = `scopestrength-assets-${VERSION}`;
const OFFLINE_URL = "/offline.html";

const CACHEABLE = ["/assets/", "/images/", "/fonts/"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(ASSETS)
      .then((cache) => cache.addAll([OFFLINE_URL, "/favicon.ico"]))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((key) => key !== ASSETS).map((key) => caches.delete(key)))
      )
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const { request } = event;

  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (url.pathname.startsWith("/live") || url.pathname.startsWith("/phoenix")) return;

  if (url.pathname.startsWith("/uploads")) return;

  if (request.mode === "navigate") {
    event.respondWith(fetch(request).catch(() => caches.match(OFFLINE_URL)));
    return;
  }

  if (!CACHEABLE.some((prefix) => url.pathname.startsWith(prefix))) return;

  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached;

      return fetch(request).then((response) => {
        if (response.ok && response.type === "basic") {
          const copy = response.clone();
          caches.open(ASSETS).then((cache) => cache.put(request, copy));
        }
        return response;
      });
    })
  );
});
