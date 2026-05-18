// Stryxs Service Worker
// Handles incoming Web Push messages and notification interactions.
// Lives at /sw.js (must be served from the root for full-scope control).

const CACHE_NAME = 'stryxs-sw-v4';

// Install + activate quickly — we don't precache anything since the
// SPA reloads on each visit and we don't need offline support yet.
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    // Nuke ALL old caches so users stuck on a stale index.html get the
    // fresh one on their very next request.
    const names = await caches.keys();
    await Promise.all(names.map(n => caches.delete(n)));
    await self.clients.claim();
  })());
});

// Force-bypass the HTTP cache for index.html so we never serve stale code
// after a deploy. Other assets (icons, etc.) can be cached normally by
// the browser. The PWA install flow uses index.html for shell rendering
// so making sure THAT is always fresh is what matters.
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  // Only intercept top-level navigations + explicit index.html requests
  if (event.request.mode === 'navigate' ||
      url.pathname === '/' ||
      url.pathname === '/index.html') {
    event.respondWith(fetch(event.request, { cache: 'reload' }).catch(() => fetch(event.request)));
  }
});

// Push event — fired when our backend sends a Web Push to this device.
// Payload is a JSON object: { title, body, url, icon, badge }.
self.addEventListener('push', (event) => {
  let data = {};
  try {
    if (event.data) data = event.data.json();
  } catch (_) {
    // Fall back to text if JSON parse fails
    data = { title: 'Stryxs', body: event.data?.text() || '' };
  }

  const title = data.title || 'Stryxs';
  const options = {
    body: data.body || '',
    icon: data.icon || '/web-app-manifest-192x192.png',
    badge: data.badge || '/web-app-manifest-192x192.png',
    tag: data.tag || 'stryxs-notification',
    // Reuse same tag so a 2nd workout reminder replaces the 1st instead
    // of stacking. Users hate stacked notifications.
    renotify: false,
    data: { url: data.url || '/' },
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

// Click — open or focus the Stryxs tab. If the user already has it open,
// focus that tab instead of opening a new one.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = event.notification.data?.url || '/';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Try to focus an existing Stryxs tab
      for (const client of clientList) {
        if (client.url.includes(self.location.host) && 'focus' in client) {
          if (targetUrl !== '/' && 'navigate' in client) {
            client.navigate(targetUrl).catch(() => {});
          }
          return client.focus();
        }
      }
      // No existing tab — open a new one
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl);
      }
    }),
  );
});

// pushsubscriptionchange — fired by the browser when our subscription
// expires or is replaced. We try to re-subscribe silently. If the page
// isn't active, the new subscription gets reconciled next time the user
// opens Stryxs.
self.addEventListener('pushsubscriptionchange', (event) => {
  // We can't access localStorage here (different context) so we just
  // log; the main app will reconcile on next open.
  console.log('[Stryxs SW] subscription changed — main app will reconcile');
});
