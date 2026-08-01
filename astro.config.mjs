import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import { SITE } from './src/site.js';

export default defineConfig({
  site: SITE.url,
  // canonical adresler eğik çizgisiz; site haritası da öyle olsun ki
  // tarayıcı botu her adreste 308 yönlendirmesine takılmasın
  trailingSlash: 'never',
  integrations: [
    sitemap({
      // noindex sayfaları site haritasına girmemeli
      filter: (sayfa) => !/\/(ara|404|ozgecmis\/yazdir)\/?$/.test(sayfa),
    }),
  ],
  build: {
    // /rehberler/slug/index.html — sondaki eğik çizgi olmadan da çalışır
    format: 'directory',
  },
});
