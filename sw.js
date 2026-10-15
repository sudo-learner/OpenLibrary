/* sw.js - service worker for OpenLibrary.
   This is what makes "Install app" possible and lets the app shell
   (the pages themselves, not the books) load instantly and even work
   offline. It does NOT cache book PDFs or live Supabase data - those
   always come fresh from the network. */

const CACHE_NAME = "openlibrary-v1";   // bump this (v2, v3, ...) whenever app files change

// The "app shell": every file needed to draw the site itself.
const PRECACHE_URLS = [
  "./",
  "index.html",
  "categories.html",
  "book.html",
  "reader.html",
  "dashboard.html",
  "favorites.html",
  "upload.html",
  "login.html",
  "offline.html",
  "css/style.css",
  "js/config.js",
  "js/common.js",
  "js/theme.js",
  "js/home.js",
  "js/categories.js",
  "js/book.js",
  "js/reader.js",
  "js/dashboard.js",
  "js/favorites.js",
  "js/upload.js",
  "js/login.js",
  "favicon.svg",
  "manifest.json",
  "icons/icon-192.png",
  "icons/icon-512.png",
];

// --- Install: download and cache the app shell, then activate right away ---
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

// --- Activate: delete any old, no-longer-needed cache, then take control ---
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((names) => Promise.all(
        names.filter((name) => name !== CACHE_NAME).map((name) => caches.delete(name))
      ))
      .then(() => self.clients.claim())
  );
});

// --- Fetch: only handle our own same-origin app-shell files ---
// Everything else (Supabase, Google Fonts, PDF.js, book PDFs) is left completely
// alone and goes straight to the network, so readers always see live data.
self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET" || new URL(req.url).origin !== self.location.origin) return;

  // Page navigations: try the network first (so content stays fresh while online),
  // fall back to the cached copy, and finally to the offline page.
  if (req.mode === "navigate") {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          return res;
        })
        .catch(() => caches.match(req).then((hit) => hit || caches.match("offline.html")))
    );
    return;
  }

  // Everything else in the app shell: serve from cache instantly, update it
  // quietly in the background for next time.
  event.respondWith(
    caches.match(req).then((hit) => {
      const network = fetch(req).then((res) => {
        const copy = res.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
        return res;
      }).catch(() => hit);
      return hit || network;
    })
  );
});
