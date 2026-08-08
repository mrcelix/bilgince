/**
 * Parola ve geçiş cümlesi üretimi. Rastgelelik crypto.getRandomValues'tan
 * gelir; Math.random() parola üretiminde kullanılmaz.
 */

export const KUMELER = {
  kucuk: 'abcdefghijklmnopqrstuvwxyz',
  buyuk: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  rakam: '0123456789',
  sembol: '!#$%&*+-=?@^_~',
};

/** Birbirine benzeyen ve yanlış okunan karakterler */
const BENZER = new Set(['I', 'l', '1', 'O', '0', 'o', 'B', '8', 'S', '5', 'Z', '2']);

/**
 * Modulo sapması olmadan 0..sinir-1 aralığında tam sayı.
 * Basit `% sinir` kullanınca ilk karakterler diğerlerinden daha sık çıkar.
 */
export function rastgeleTam(sinir) {
  if (sinir <= 0) throw new Error('Sınır pozitif olmalı.');
  const enBuyuk = Math.floor(0xffffffff / sinir) * sinir;
  const tampon = new Uint32Array(1);
  let deger;
  do {
    crypto.getRandomValues(tampon);
    deger = tampon[0];
  } while (deger >= enBuyuk);
  return deger % sinir;
}

export function rastgeleSec(dizi) {
  return dizi[rastgeleTam(dizi.length)];
}

/** Fisher–Yates, kriptografik kaynakla */
function karistir(dizi) {
  for (let i = dizi.length - 1; i > 0; i--) {
    const j = rastgeleTam(i + 1);
    [dizi[i], dizi[j]] = [dizi[j], dizi[i]];
  }
  return dizi;
}

/**
 * @param {{uzunluk:number, kucuk:boolean, buyuk:boolean, rakam:boolean,
 *          sembol:boolean, benzerleriEle:boolean, herKumedenEnAz:boolean}} ayar
 */
export function parolaUret(ayar) {
  const secili = Object.keys(KUMELER).filter((k) => ayar[k]);
  if (!secili.length) throw new Error('En az bir karakter kümesi seçin.');

  const suz = (metin) => (ayar.benzerleriEle ? [...metin].filter((c) => !BENZER.has(c)).join('') : metin);
  const kumeler = secili.map((k) => suz(KUMELER[k])).filter((k) => k.length);
  if (!kumeler.length) throw new Error('Benzer karakterler elenince küme boş kaldı.');

  const havuz = kumeler.join('');
  const harfler = [];

  // Her kümeden en az bir karakter: politika denetimlerini geçmek için
  if (ayar.herKumedenEnAz && ayar.uzunluk >= kumeler.length) {
    for (const kume of kumeler) harfler.push(rastgeleSec(kume));
  }
  while (harfler.length < ayar.uzunluk) harfler.push(rastgeleSec(havuz));

  return { parola: karistir(harfler).join(''), havuzBoyu: havuz.length };
}

/** Karakter parolası için entropi: uzunluk × log2(havuz) */
export function karakterEntropi(uzunluk, havuzBoyu) {
  return uzunluk * Math.log2(havuzBoyu);
}

/**
 * Geçiş cümlesi. Kelime listesi 256 sözcük olduğu için her kelime tam 8 bit
 * entropi taşır — hesabı okuyucuya açıklamak kolay olsun diye böyle seçildi.
 */
export function gecisCumlesi(ayar, kelimeler) {
  const secilen = Array.from({ length: ayar.kelimeSayisi }, () => rastgeleSec(kelimeler));
  let parcalar = secilen.map((k) => (ayar.basHarfBuyuk ? k[0].toLocaleUpperCase('tr') + k.slice(1) : k));

  let ekBit = 0;
  if (ayar.sayiEkle) {
    const konum = rastgeleTam(parcalar.length);
    parcalar[konum] += String(rastgeleTam(100)).padStart(2, '0');
    ekBit = Math.log2(100 * parcalar.length);
  }
  const metin = parcalar.join(ayar.ayirici);
  const bit = ayar.kelimeSayisi * Math.log2(kelimeler.length) + ekBit;
  return { parola: metin, bit };
}

/**
 * Çevrimdışı, hızlı donanımla saldırı varsayımı: saniyede 10¹¹ deneme.
 * Sızdırılmış bir karma dosyası eldeyse gerçekçi olan budur; "tarayıcıdan
 * deneme" varsayımı parolaları olduğundan güçlü gösterir.
 */
export function kirilmaSuresi(bit) {
  const saniye = Math.pow(2, bit - 1) / 1e11;
  const olcek = [
    [1, 'saniyeden az'],
    [60, 'saniye'],
    [3600, 'dakika'],
    [86400, 'saat'],
    [2592000, 'gün'],
    [31557600, 'ay'],
    [3155760000, 'yıl'],
  ];
  if (saniye < 1) return 'anında';
  if (saniye < 60) return `${Math.round(saniye)} saniye`;
  if (saniye < 3600) return `${Math.round(saniye / 60)} dakika`;
  if (saniye < 86400) return `${Math.round(saniye / 3600)} saat`;
  if (saniye < 2592000) return `${Math.round(saniye / 86400)} gün`;
  if (saniye < 31557600) return `${Math.round(saniye / 2592000)} ay`;
  const yil = saniye / 31557600;
  if (yil < 1000) return `${Math.round(yil)} yıl`;
  if (yil < 1e6) return `${Math.round(yil / 1000)} bin yıl`;
  if (yil < 1e9) return `${Math.round(yil / 1e6)} milyon yıl`;
  if (yil < 1e12) return `${Math.round(yil / 1e9)} milyar yıl`;
  return 'evrenin yaşından uzun';
}

/** Entropiye göre kaba güç sınıfı — göstergenin rengi ve metni buradan */
export function guc(bit) {
  if (bit < 40) return { ad: 'zayıf', sinif: 'zayif', oran: Math.max(8, (bit / 40) * 33) };
  if (bit < 60) return { ad: 'orta', sinif: 'orta', oran: 33 + ((bit - 40) / 20) * 27 };
  if (bit < 80) return { ad: 'güçlü', sinif: 'guclu', oran: 60 + ((bit - 60) / 20) * 25 };
  return { ad: 'çok güçlü', sinif: 'cok-guclu', oran: 100 };
}

/**
 * Yaygın örüntüler — entropi hesabı bunları görmez. "Ankara2026!" matematiksel
 * olarak 72 bit görünür ama sözlük saldırısında saniyeler içinde düşer.
 */
const YAYGIN = [
  '123456', '1234567', '12345678', '123456789', '1234567890', 'password', 'parola',
  'qwerty', 'asdf', 'zxcv', 'iloveyou', 'admin', 'welcome', 'sifre', 'şifre',
  'galatasaray', 'fenerbahce', 'besiktas', 'trabzonspor', 'ankara', 'istanbul', 'izmir',
  'turkiye', 'türkiye', 'deneme', 'test', 'merhaba', 'sevgi', 'ask', 'aşk', 'canim',
];

export function orunutuBul(parola) {
  const bulgular = [];
  const kucuk = parola.toLocaleLowerCase('tr');

  for (const kalip of YAYGIN) {
    if (kucuk.includes(kalip)) {
      bulgular.push(`Yaygın bir sözcük içeriyor: "${kalip}"`);
      break;
    }
  }
  if (/(.)\1{2,}/.test(parola)) bulgular.push('Aynı karakter üç kez üst üste tekrarlıyor.');
  if (/(19|20)\d{2}/.test(parola)) bulgular.push('İçinde yıl gibi görünen dört haneli bir sayı var.');
  if (/^[A-ZĞÜŞİÖÇ][a-zğüşıöç]+\d{1,4}[!.?*]?$/.test(parola)) {
    bulgular.push('“Kelime + sayı + işaret” kalıbı sözlük saldırılarının ilk denediği biçimdir.');
  }
  const klavye = ['qwerty', 'asdfgh', 'zxcvbn', '123456', 'qazwsx'];
  if (klavye.some((k) => kucuk.includes(k))) bulgular.push('Klavyede yan yana duran tuş dizisi içeriyor.');
  if (parola.length < 12) bulgular.push('12 karakterin altındaki parolalar bugünün donanımıyla kısa sayılır.');
  return bulgular;
}
