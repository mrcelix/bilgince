import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';
import react from '@astrojs/react';
import keystatic from '@keystatic/astro';
import vercel from '@astrojs/vercel';
import { readFileSync } from 'node:fs';

// site.js JSON içe aktarımı kullanıyor; yapılandırma dosyası Node tarafında
// çalıştığı için veriyi doğrudan okuyoruz.
const ayarlar = JSON.parse(readFileSync(new URL('./src/data/ayarlar.json', import.meta.url), 'utf8'));

export default defineConfig({
  site: ayarlar.adres,
  // canonical adresler eğik çizgisiz; site haritası da öyle olsun ki
  // tarayıcı botu her adreste 308 yönlendirmesine takılmasın
  trailingSlash: 'never',

  // İçerik sayfaları statik üretilir; yalnızca /keystatic ve /api/keystatic
  // sunucu tarafında çalışır. Adaptör bunun için gerekli.
  output: 'static',
  // AI görsel üretimi 10 sn'lik varsayılanı aşabiliyor
  adapter: vercel({ maxDuration: 60 }),

  // panel /keystatic altında; /admin alışkanlığı için kısayol
  redirects: {
    '/admin': '/keystatic',
  },

  integrations: [
    mdx(),
    react(),
    keystatic(),
    sitemap({
      // noindex ve yönetim sayfaları site haritasına girmemeli
      filter: (sayfa) => !/\/(ara|404|ozgecmis\/yazdir|keystatic|admin|api)(\/|$)/.test(sayfa),
    }),
  ],

  build: {
    format: 'directory',
  },
});
