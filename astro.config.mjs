import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import { SITE } from './src/site.js';

export default defineConfig({
  site: SITE.url,
  integrations: [sitemap()],
  build: {
    // /rehberler/slug/index.html — sondaki eğik çizgi olmadan da çalışır
    format: 'directory',
  },
});
