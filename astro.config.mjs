import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';
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

  // İçerik sayfaları statik üretilir; sunucu tarafında çalışanlar yalnızca
  // yönetim paneli (/admin, /api/admin) ve araç uçları. Adaptör bunun için.
  output: 'static',
  // AI görsel üretimi ve tarayıcı işleme 10 sn'lik varsayılanı aşabiliyor
  adapter: vercel({ maxDuration: 60 }),

  integrations: [
    mdx(),
    sitemap({
      // noindex ve yönetim sayfaları site haritasına girmemeli
      filter: (sayfa) => !/\/(ara|404|ozgecmis\/yazdir|admin|api)(\/|$)/.test(sayfa),
    }),
  ],

  build: {
    format: 'directory',
  },
});
