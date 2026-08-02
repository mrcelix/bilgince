// Site verisi artık src/data/*.json içinde tutuluyor; admin paneli (Keystatic)
// bu dosyaları düzenliyor. Buradaki dışa aktarımlar sayfaların kullandığı
// arayüzü koruyor, böylece panel eklendiğinde hiçbir sayfa değişmedi.
import ayarlar from './data/ayarlar.json';
import menuVerisi from './data/menu.json';

// Her konu ayrı bir JSON dosyası — admin panelinde koleksiyon olarak yönetiliyor.
// Dosya adı slug'dır.
const konuDosyalari = import.meta.glob('./data/konu/*.json', { eager: true });

export const SITE = {
  name: ayarlar.ad,
  url: ayarlar.adres,
  title: ayarlar.baslik,
  description: ayarlar.aciklama,
  locale: 'tr_TR',
  lang: 'tr',
  author: {
    name: ayarlar.yazar.ad,
    initials: ayarlar.yazar.basHarfler,
    jobTitle: ayarlar.yazar.unvan,
    worksFor: ayarlar.yazar.kurum,
    location: ayarlar.yazar.sehir,
    email: ayarlar.yazar.eposta,
    linkedin: ayarlar.yazar.linkedin,
    github: ayarlar.yazar.github,
    knowsAbout: ayarlar.yazar.uzmanlik,
  },
  newsletter: {
    subscribers: ayarlar.bulten.aboneSayisi,
    cadence: ayarlar.bulten.sikligi,
    vaat: ayarlar.bulten.vaat,
    endpoint: ayarlar.bulten.endpoint,
    alanAdi: ayarlar.bulten.alanAdi,
  },
};

export const GRUPLAR = menuVerisi.kumeler;

export const KONULAR = Object.entries(konuDosyalari)
  .map(([yol, modul]) => {
    const veri = modul.default ?? modul;
    return { slug: yol.split('/').pop().replace('.json', ''), ...veri };
  })
  .sort((a, b) => (a.sira ?? 999) - (b.sira ?? 999));

export const MENU = menuVerisi;
export const POPULER_ARAMALAR = ayarlar.populerAramalar;
export const SAYFA_BASI = ayarlar.sayfaBasi;

/**
 * Türkçe karakterleri koruyarak URL parçası üretir.
 * "Sıfırdan Active Directory" → "sifirdan-active-directory"
 * @param {string} metin
 */
export function slugla(metin) {
  // Türkçe harfleri KÜÇÜLTMEDEN ÖNCE çevir: 'I' Türkçe kurallarla 'ı' olur ve
  // sonraki filtrede elenir — "Entra ID" → "entra d" gibi bir sonuç çıkardı.
  const harita = {
    ç: 'c', Ç: 'c', ğ: 'g', Ğ: 'g', ı: 'i', I: 'i', İ: 'i',
    ö: 'o', Ö: 'o', ş: 's', Ş: 's', ü: 'u', Ü: 'u',
  };
  return metin
    .replace(/[çÇğĞıIİöÖşŞüÜ]/g, (h) => harita[h] ?? h)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/** @param {Date} d */
export function trTarih(d) {
  return new Intl.DateTimeFormat('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' }).format(d);
}

/** @param {Date} d */
export function trKisaTarih(d) {
  return new Intl.DateTimeFormat('tr-TR', { day: '2-digit', month: 'short', year: 'numeric' }).format(d);
}

/** @param {number} n */
export function sayi(n) {
  return new Intl.NumberFormat('tr-TR').format(n);
}
