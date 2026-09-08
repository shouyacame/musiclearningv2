const CACHE_NAME = 'music-learning-v2';
const STATIC_FILES = [
  './',
  './index.html',
  './teacher.html',
  './teacher-login.html',
  './student.html',
  './admin.html',
  './admin-login.html',
  './study-preview.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './supabase-config.js'
];

// インストール時: 静的ファイルをキャッシュ
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(STATIC_FILES))
  );
  self.skipWaiting();
});

// 有効化時: 古いキャッシュを削除
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// リクエスト時の戦略
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);

  // Supabase API 通信は常にネット経由（キャッシュしない）
  if (url.hostname.includes('supabase.co')) return;

  // 静的ファイル: キャッシュ優先、なければネット取得
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(res => {
        if (res && res.status === 200 && res.type !== 'opaque') {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
        }
        return res;
      });
    })
  );
});
