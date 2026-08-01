import type { APIRoute } from 'astro';
import { SITE } from '../site.js';

// Alan adı tek yerde (src/site.js) dursun diye robots.txt de üretiliyor;
// public/robots.txt gibi elle güncellenmesi unutulan bir kopya kalmıyor.
export const GET: APIRoute = () =>
  new Response(
    `User-agent: *
Allow: /

# Site içi arama sonuçları indekslenmesin
Disallow: /ara

Sitemap: ${SITE.url}/sitemap-index.xml
`,
    { headers: { 'Content-Type': 'text/plain; charset=utf-8' } }
  );
