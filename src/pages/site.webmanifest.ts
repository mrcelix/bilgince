import type { APIRoute } from 'astro';
import { SITE } from '../site.js';

/**
 * Web app manifest. Android'de ana ekrana eklenince uygulama adı ve ikonu
 * buradan okunuyor; olmadan alan adı ve bulanık bir ekran görüntüsü çıkıyordu.
 * Ad ve adres `src/data/ayarlar.json` tek kaynağından geliyor.
 */
export const GET: APIRoute = () =>
  new Response(
    JSON.stringify(
      {
        name: SITE.title,
        short_name: SITE.name,
        description: SITE.description,
        lang: 'tr',
        dir: 'ltr',
        start_url: '/',
        scope: '/',
        // Tarayıcı olarak açılıyor: site bir uygulama değil, okunacak içerik.
        display: 'browser',
        background_color: '#f4f6f9',
        theme_color: '#16203a',
        icons: [
          { src: '/ikon/192.png', sizes: '192x192', type: 'image/png' },
          { src: '/ikon/512.png', sizes: '512x512', type: 'image/png' },
          { src: '/ikon/512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
          { src: '/favicon.svg', sizes: 'any', type: 'image/svg+xml' },
        ],
      },
      null,
      2
    ),
    { headers: { 'Content-Type': 'application/manifest+json; charset=utf-8' } }
  );
