import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { DERLEME } from '../derleme.js';

/**
 * Service worker. Sunucu odasında ve veri merkezinde internet yok; komut
 * kütüphanesi, tanı sihirbazı ve saha çantası orada işe yarayacak şeyler.
 *
 * Strateji sayfa türüne göre:
 * - Kabuk (komutlar, tanı, çanta, indeks) kurulumda önbelleğe alınıyor —
 *   çevrimdışı ilk açılışta da hazır.
 * - Gezinme istekleri önce ağdan, olmazsa önbellekten, o da yoksa çevrimdışı
 *   sayfasından. Ağ önce çünkü içerik sık güncelleniyor.
 * - Değişmez varlıklar (/_astro, /fonts, /og, /ikon) önce önbellekten.
 * - Betikler (/araclar/*.ps1) ağdan gelince saklanıyor: bir kez indirdiğiniz
 *   betik çevrimdışı da elinizin altında.
 *
 * Önbellek adı derleme numarasını taşıyor: yeni dağıtımda eskisi siliniyor,
 * bayat sayfa gösterme sorunu olmuyor.
 */
export const GET: APIRoute = async () => {
  const cozumler = await getCollection('cozumler');

  // Kurulumda indirilecek çekirdek: gezinilecek sayfalar ve veri uçları
  const kabuk = [
    '/',
    '/komutlar',
    '/tani',
    '/canta',
    '/canta.json',
    '/hizli-cozumler',
    '/araclar',
    '/cevrimdisi',
    '/favicon.svg',
    '/ikon/192.png',
    '/fonts/nunito-latin.woff2',
    '/fonts/nunito-latin-ext.woff2',
  ];

  // Hızlı çözüm sayfaları da kabuğa giriyor: sihirbazın gönderdiği yerler
  const cozumYollari = cozumler.map((c) => `/hizli-cozumler/${c.id}`);

  const govde = `/* bilgince service worker — derleme ${DERLEME.surum} */
const SURUM = ${JSON.stringify(DERLEME.surum)};
const KABUK_ADI = 'bilgince-kabuk-' + SURUM;
const VARLIK_ADI = 'bilgince-varlik-' + SURUM;
const KABUK = ${JSON.stringify([...kabuk, ...cozumYollari])};

/* Kurulum: çekirdek sayfaları indir. Tek bir adres başarısız olursa kurulum
   tamamen çökmesin — addAll hepsini birden ister, o yüzden tek tek ekleniyor. */
self.addEventListener('install', (olay) => {
  olay.waitUntil(
    caches.open(KABUK_ADI).then((onbellek) =>
      Promise.all(
        KABUK.map((yol) =>
          onbellek.add(new Request(yol, { cache: 'reload' })).catch(() => {})
        )
      )
    )
  );
  self.skipWaiting();
});

/* Etkinleşme: eski derlemelerin önbelleklerini sil. */
self.addEventListener('activate', (olay) => {
  olay.waitUntil(
    caches
      .keys()
      .then((adlar) =>
        Promise.all(
          adlar
            .filter((a) => a.startsWith('bilgince-') && !a.endsWith(SURUM))
            .map((a) => caches.delete(a))
        )
      )
      .then(() => self.clients.claim())
  );
});

const degismezMi = (yol) =>
  /^\\/(_astro|fonts|og|ikon)\\//.test(yol) || yol === '/favicon.svg';

const betikMi = (yol) => /^\\/araclar\\/.+\\.(ps1|zip|txt)$/i.test(yol);

self.addEventListener('fetch', (olay) => {
  const istek = olay.request;
  if (istek.method !== 'GET') return;

  const adres = new URL(istek.url);
  if (adres.origin !== location.origin) return;

  // Yönetim paneli ve uçları asla önbelleğe girmemeli: oturum ve tazelik
  if (adres.pathname.startsWith('/admin') || adres.pathname.startsWith('/api/')) return;

  // Değişmez varlıklar: önce önbellek
  if (degismezMi(adres.pathname)) {
    olay.respondWith(
      caches.match(istek).then(
        (yanit) =>
          yanit ??
          fetch(istek).then((ag) => {
            const kopya = ag.clone();
            caches.open(VARLIK_ADI).then((o) => o.put(istek, kopya));
            return ag;
          })
      )
    );
    return;
  }

  // İndirilebilir betikler: ağdan gelirse sakla, yoksa önbellekten ver
  if (betikMi(adres.pathname)) {
    olay.respondWith(
      fetch(istek)
        .then((ag) => {
          const kopya = ag.clone();
          caches.open(VARLIK_ADI).then((o) => o.put(istek, kopya));
          return ag;
        })
        .catch(() => caches.match(istek).then((y) => y ?? yanitYok()))
    );
    return;
  }

  // Sayfalar ve veri: önce ağ, sonra önbellek, sonra çevrimdışı sayfası
  olay.respondWith(
    fetch(istek)
      .then((ag) => {
        if (ag.ok) {
          const kopya = ag.clone();
          caches.open(KABUK_ADI).then((o) => o.put(istek, kopya));
        }
        return ag;
      })
      .catch(() =>
        caches.match(istek).then((y) => {
          if (y) return y;
          if (istek.mode === 'navigate') return caches.match('/cevrimdisi');
          return yanitYok();
        })
      )
  );
});

const yanitYok = () =>
  new Response('Çevrimdışı ve bu içerik önbellekte yok.', {
    status: 503,
    headers: { 'content-type': 'text/plain; charset=utf-8' },
  });
`;

  return new Response(govde, {
    headers: {
      'content-type': 'text/javascript; charset=utf-8',
      // Service worker dosyası önbelleklenmemeli; yenisi hemen görülsün
      'cache-control': 'no-cache',
      'service-worker-allowed': '/',
    },
  });
};
