import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';
import vercel from '@astrojs/vercel';
import { readFileSync, readdirSync } from 'node:fs';

// site.js JSON içe aktarımı kullanıyor; yapılandırma dosyası Node tarafında
// çalıştığı için veriyi doğrudan okuyoruz.
const ayarlar = JSON.parse(readFileSync(new URL('./src/data/ayarlar.json', import.meta.url), 'utf8'));

/* Site haritasındaki <lastmod>: arama motoru hangi sayfayı yeniden tarayacağına
   buna bakarak karar veriyor. Tarih içerik dosyalarının ön bilgisinden okunuyor
   (guncelleme varsa o, yoksa yayin). Yapılandırma Node tarafında çalıştığı için
   koleksiyon API'si yok; dosyaları doğrudan tarıyoruz. */
function icerikTarihleri() {
  const harita = new Map();
  const kokler = [
    ['rehberler', './src/content/rehberler'],
    ['hizli-cozumler', './src/content/cozumler'],
    ['ipuclari', './src/content/ipuclari'],
  ];

  for (const [yolBasi, klasor] of kokler) {
    let dosyalar;
    try {
      dosyalar = readdirSync(new URL(klasor, import.meta.url));
    } catch {
      continue; // klasör yoksa sessizce geç
    }
    for (const dosya of dosyalar) {
      if (!/\.mdx?$/.test(dosya)) continue;
      const metin = readFileSync(new URL(`${klasor}/${dosya}`, import.meta.url), 'utf8');
      const on = metin.split(/^---\s*$/m)[1] ?? '';
      const guncelleme = on.match(/^guncelleme:\s*(\S+)/m)?.[1];
      const yayin = on.match(/^yayin:\s*(\S+)/m)?.[1];
      const tarih = guncelleme ?? yayin;
      if (!tarih) continue;
      const slug = dosya.replace(/\.mdx?$/, '');
      harita.set(`${ayarlar.adres}/${yolBasi}/${slug}`, new Date(tarih));
    }
  }
  return harita;
}

const TARIHLER = icerikTarihleri();

/* Markdown tablolarını kaydırılabilir bir kapsayıcıya sarar. Dar ekranda geniş
   tablo sayfanın tamamını yatay kaydırıyordu; artık yalnızca tablo kayıyor.
   Kapsayıcı `tabindex="0"` ile klavyeden de kaydırılabiliyor — kaydırılabilir
   bölgelerin erişilebilirlik gereği. */
function tablolariSar() {
  return (agac) => {
    const gez = (dugum) => {
      if (!Array.isArray(dugum.children)) return;
      dugum.children = dugum.children.map((cocuk) => {
        gez(cocuk);
        if (cocuk.type !== 'element' || cocuk.tagName !== 'table') return cocuk;
        return {
          type: 'element',
          tagName: 'div',
          properties: {
            className: ['tablo-sar'],
            tabIndex: 0,
            role: 'region',
            'aria-label': 'Tablo — yatay kaydırılabilir',
          },
          children: [cocuk],
        };
      });
    };
    gez(agac);
  };
}

/** Liste ve giriş sayfaları en yeni içerikle birlikte tazelenir. */
const enYeni = [...TARIHLER.values()].sort((a, b) => b - a)[0] ?? new Date();

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

  markdown: {
    rehypePlugins: [tablolariSar],
  },

  integrations: [
    mdx(),
    sitemap({
      // noindex ve yönetim sayfaları site haritasına girmemeli
      filter: (sayfa) => !/\/(ara|404|ozgecmis\/yazdir|admin|api)(\/|$)/.test(sayfa),
      serialize(oge) {
        const adres = oge.url.replace(/\/$/, '');
        const tarih = TARIHLER.get(adres);

        if (tarih) {
          oge.lastmod = tarih;
          oge.changefreq = 'yearly'; // yazılar yayımlandıktan sonra nadiren değişir
          oge.priority = 0.8;
          return oge;
        }

        // Liste sayfaları yeni içerik geldikçe değişiyor
        if (/\/(rehberler|hizli-cozumler|ipuclari|komutlar|araclar|konu|etiket|seri)(\/|$)/.test(adres)) {
          oge.lastmod = enYeni;
          oge.changefreq = 'weekly';
          oge.priority = 0.6;
          return oge;
        }

        oge.lastmod = enYeni;
        oge.changefreq = adres === ayarlar.adres ? 'daily' : 'monthly';
        oge.priority = adres === ayarlar.adres ? 1 : 0.5;
        return oge;
      },
    }),
  ],

  // Site içi bağlantılar fareyle üzerine gelindiğinde önden çekiliyor: tıklama
  // ile boyama arasındaki bekleme pratikte kayboluyor. `hover` seçildi çünkü
  // `viewport` bu sayfalarda (bir listede 12+ bağlantı) gereksiz indirme yapıyor.
  prefetch: {
    prefetchAll: true,
    defaultStrategy: 'hover',
  },

  experimental: {
    // Destekleyen tarayıcılarda prefetch yerine Speculation Rules kullanılır:
    // sayfa yalnızca indirilmez, önden işlenir de.
    clientPrerender: true,
  },

  build: {
    format: 'directory',
  },
});
