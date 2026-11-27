const CACHE = "otkat-games-shell-v2";
const CORE = [
  "./",
  "./index.html",
  "./styles.css",
  "./apps/index.html",
  "./games/index.html",
  "./collection-app.js",
  "./manifest.webmanifest",
  "./apps/arcade-mix/index.html",
  "./apps/puzzle-lab/index.html",
  "./apps/party-duo/index.html",
  "./apps/action-rush/index.html",
  "./apps/cozy-worlds/index.html"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE)
      .then((cache) => cache.addAll(CORE))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys.filter((key) => key.startsWith("otkat-") && key !== CACHE)
          .map((key) => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request)
        .then((response) => {
          if (response.ok) {
            const copy = response.clone();
            caches.open(CACHE).then((cache) => cache.put(request, copy));
          }
          return response;
        })
        .catch(async () => {
          const cached = await caches.match(request);
          if (cached) return cached;
          const path = url.pathname;
          const knownFallback = path.includes("/apps/")
            ? "./apps/index.html"
            : "./index.html";
          return (await caches.match(knownFallback)) ||
            new Response("Эта страница ещё не сохранена для офлайн-режима. Откройте её при подключении к интернету.", {
              status: 503,
              headers: { "Content-Type": "text/plain; charset=utf-8" }
            });
        })
    );
    return;
  }

  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached;
      return fetch(request).then((response) => {
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE).then((cache) => cache.put(request, copy));
        }
        return response;
      });
    })
  );
});
