/**
 * QR kod üreteci — bayt kipi (UTF-8), sürüm 1–10, dört hata düzeltme seviyesi.
 * Dışarıdan kütüphane çekmiyoruz: araç sayfası tamamen tarayıcıda çalışsın ve
 * girilen Wi-Fi parolası hiçbir ağ isteğine karışmasın diye.
 *
 * ISO/IEC 18004. Sürüm 10'da bayt kapasitesi ~270 karakter; Wi-Fi ve URL
 * yükleri için fazlasıyla yeterli, tablo da o kadarıyla sınırlı tutuldu.
 */

/* --------------------------------------------------------------- GF(256) */

const USTEL = new Uint8Array(512);
const LOG = new Uint8Array(256);
(() => {
  let x = 1;
  for (let i = 0; i < 255; i++) {
    USTEL[i] = x;
    LOG[x] = i;
    x <<= 1;
    if (x & 0x100) x ^= 0x11d; // x^8 + x^4 + x^3 + x^2 + 1
  }
  for (let i = 255; i < 512; i++) USTEL[i] = USTEL[i - 255];
})();

const carp = (a, b) => (a && b ? USTEL[LOG[a] + LOG[b]] : 0);

/** Reed–Solomon bölen polinomu: (x-α⁰)(x-α¹)…(x-α^(derece-1)) */
function bolenPoli(derece) {
  const p = new Uint8Array(derece);
  p[derece - 1] = 1;
  let kok = 1;
  for (let i = 0; i < derece; i++) {
    for (let j = 0; j < derece; j++) {
      p[j] = carp(p[j], kok);
      if (j + 1 < derece) p[j] ^= p[j + 1];
    }
    kok = carp(kok, 2);
  }
  return p;
}

/** Veri kod sözcüklerinin hata düzeltme kalanı */
function ecKodlari(veri, derece) {
  const bolen = bolenPoli(derece);
  const kalan = new Uint8Array(derece);
  for (const bayt of veri) {
    const faktor = bayt ^ kalan[0];
    kalan.copyWithin(0, 1);
    kalan[derece - 1] = 0;
    for (let i = 0; i < derece; i++) kalan[i] ^= carp(bolen[i], faktor);
  }
  return kalan;
}

/* ------------------------------------------------------- sürüm tabloları */

// Blok başına EC kod sözcüğü ve blok sayısı (sürüm 1–10).
// Veri kod sözcüğü sayısı bunlardan hesaplanır, ayrı tablo tutulmaz.
const EC_KOD = {
  L: [7, 10, 15, 20, 26, 18, 20, 24, 30, 18],
  M: [10, 16, 26, 18, 24, 16, 18, 22, 22, 26],
  Q: [13, 22, 18, 26, 18, 24, 18, 22, 20, 24],
  H: [17, 28, 22, 16, 22, 28, 26, 26, 24, 28],
};
const BLOK = {
  L: [1, 1, 1, 1, 1, 2, 2, 2, 2, 4],
  M: [1, 1, 1, 2, 2, 4, 4, 4, 5, 5],
  Q: [1, 1, 2, 2, 4, 4, 6, 6, 8, 8],
  H: [1, 1, 2, 4, 4, 4, 5, 6, 8, 8],
};
const SEVIYE_BIT = { L: 1, M: 0, Q: 3, H: 2 };

// Hizalama deseni merkezleri (sürüm 2–10); sürüm 1'de desen yok.
const HIZALAMA = [
  [], [], [6, 18], [6, 22], [6, 26], [6, 30], [6, 34],
  [6, 22, 38], [6, 24, 42], [6, 26, 46], [6, 28, 50],
];

const EN_BUYUK_SURUM = 10;

/* ------------------------------------------------------------- matris */

function bosMatris(boyut) {
  return {
    modul: Array.from({ length: boyut }, () => new Uint8Array(boyut)),
    islev: Array.from({ length: boyut }, () => new Uint8Array(boyut)),
    boyut,
  };
}

function kutuCiz(m, x, y, en, boy, deger) {
  for (let dy = 0; dy < boy; dy++) {
    for (let dx = 0; dx < en; dx++) {
      const px = x + dx;
      const py = y + dy;
      if (px < 0 || py < 0 || px >= m.boyut || py >= m.boyut) continue;
      m.modul[py][px] = deger;
      m.islev[py][px] = 1;
    }
  }
}

/** Bulucu deseni + ayırıcı: 7×7 desen, çevresinde bir modül boşluk */
function bulucuCiz(m, x, y) {
  kutuCiz(m, x - 1, y - 1, 9, 9, 0);
  kutuCiz(m, x, y, 7, 7, 1);
  kutuCiz(m, x + 1, y + 1, 5, 5, 0);
  kutuCiz(m, x + 2, y + 2, 3, 3, 1);
}

function hizalamaCiz(m, cx, cy) {
  kutuCiz(m, cx - 2, cy - 2, 5, 5, 1);
  kutuCiz(m, cx - 1, cy - 1, 3, 3, 0);
  kutuCiz(m, cx, cy, 1, 1, 1);
}

/** Biçim ve sürüm alanları veriden önce ayrılır; içerikleri sonra yazılır. */
function islevDesenleri(m, surum) {
  const b = m.boyut;

  bulucuCiz(m, 0, 0);
  bulucuCiz(m, b - 7, 0);
  bulucuCiz(m, 0, b - 7);

  // zamanlama şeritleri
  for (let i = 8; i < b - 8; i++) {
    const deger = i % 2 === 0 ? 1 : 0;
    m.modul[6][i] = deger;
    m.islev[6][i] = 1;
    m.modul[i][6] = deger;
    m.islev[i][6] = 1;
  }

  // hizalama desenleri — bulucu desenlerle çakışanlar atlanır
  const merkezler = HIZALAMA[surum];
  for (const cy of merkezler) {
    for (const cx of merkezler) {
      const kose =
        (cx === 6 && cy === 6) ||
        (cx === 6 && cy === b - 7) ||
        (cx === b - 7 && cy === 6);
      if (!kose) hizalamaCiz(m, cx, cy);
    }
  }

  // biçim bilgisi alanları
  for (let i = 0; i < 9; i++) {
    if (i !== 6) {
      m.islev[8][i] = 1;
      m.islev[i][8] = 1;
    }
  }
  for (let i = 0; i < 8; i++) {
    m.islev[8][b - 1 - i] = 1;
    m.islev[b - 1 - i][8] = 1;
  }
  m.islev[8][6] = 1;
  m.islev[6][8] = 1;

  // koyu modül
  m.modul[b - 8][8] = 1;
  m.islev[b - 8][8] = 1;

  if (surum >= 7) {
    for (let i = 0; i < 18; i++) {
      const a = Math.floor(i / 3);
      const c = (i % 3) + b - 11;
      m.islev[c][a] = 1;
      m.islev[a][c] = 1;
    }
  }
}

/** İşlev deseni olmayan modül sayısından toplam kod sözcüğü sayısı */
function toplamKodSozcugu(surum) {
  const m = bosMatris(17 + 4 * surum);
  islevDesenleri(m, surum);
  let bos = 0;
  for (let y = 0; y < m.boyut; y++) for (let x = 0; x < m.boyut; x++) if (!m.islev[y][x]) bos++;
  return Math.floor(bos / 8);
}

const TOPLAM = Array.from({ length: EN_BUYUK_SURUM + 1 }, (_, v) => (v ? toplamKodSozcugu(v) : 0));

function veriKapasitesi(surum, seviye) {
  return TOPLAM[surum] - EC_KOD[seviye][surum - 1] * BLOK[seviye][surum - 1];
}

/* ------------------------------------------------------------- kodlama */

function baytlar(metin) {
  return new TextEncoder().encode(metin);
}

/** Bayt kipi bit dizisi: kip (4 bit) + uzunluk + veri + dolgu */
function bitDizisi(veri, surum, seviye) {
  const kapasite = veriKapasitesi(surum, seviye) * 8;
  const bitler = [];
  const ekle = (deger, adet) => {
    for (let i = adet - 1; i >= 0; i--) bitler.push((deger >>> i) & 1);
  };

  ekle(0b0100, 4); // bayt kipi
  ekle(veri.length, surum < 10 ? 8 : 16);
  for (const b of veri) ekle(b, 8);

  // sonlandırıcı en fazla dört bit, sonra bayt sınırına tamamlama
  for (let i = 0; i < 4 && bitler.length < kapasite; i++) bitler.push(0);
  while (bitler.length % 8 !== 0) bitler.push(0);

  const kodlar = [];
  for (let i = 0; i < bitler.length; i += 8) {
    let bayt = 0;
    for (let j = 0; j < 8; j++) bayt = (bayt << 1) | bitler[i + j];
    kodlar.push(bayt);
  }
  // dolgu baytları dönüşümlü: 11101100, 00010001
  for (let i = 0; kodlar.length < kapasite / 8; i++) kodlar.push(i % 2 === 0 ? 0xec : 0x11);
  return kodlar;
}

/** Blokları oluşturup veri ve EC kod sözcüklerini araya diz */
function kodAkisi(kodlar, surum, seviye) {
  const blokSayisi = BLOK[seviye][surum - 1];
  const ecUzunluk = EC_KOD[seviye][surum - 1];
  const veriSayisi = kodlar.length;
  const kisaBlok = Math.floor(veriSayisi / blokSayisi);
  const uzunBlokSayisi = veriSayisi % blokSayisi;

  const veriBloklari = [];
  const ecBloklari = [];
  let konum = 0;
  for (let i = 0; i < blokSayisi; i++) {
    const uzunluk = kisaBlok + (i >= blokSayisi - uzunBlokSayisi ? 1 : 0);
    const blok = kodlar.slice(konum, konum + uzunluk);
    konum += uzunluk;
    veriBloklari.push(blok);
    ecBloklari.push(ecKodlari(blok, ecUzunluk));
  }

  const akis = [];
  const enUzunVeri = kisaBlok + (uzunBlokSayisi ? 1 : 0);
  for (let i = 0; i < enUzunVeri; i++) {
    for (const blok of veriBloklari) if (i < blok.length) akis.push(blok[i]);
  }
  for (let i = 0; i < ecUzunluk; i++) {
    for (const blok of ecBloklari) akis.push(blok[i]);
  }
  return akis;
}

/** Zikzak yerleşim: sağdan sola ikişer sütun, 6. sütun atlanır */
function veriYerlestir(m, akis) {
  let bit = 0;
  const oku = () => {
    if (bit >= akis.length * 8) return 0;
    const deger = (akis[bit >>> 3] >>> (7 - (bit & 7))) & 1;
    bit++;
    return deger;
  };

  let yukari = true;
  for (let sag = m.boyut - 1; sag >= 1; sag -= 2) {
    if (sag === 6) sag = 5;
    for (let adim = 0; adim < m.boyut; adim++) {
      const y = yukari ? m.boyut - 1 - adim : adim;
      for (let s = 0; s < 2; s++) {
        const x = sag - s;
        if (m.islev[y][x]) continue;
        m.modul[y][x] = oku();
      }
    }
    yukari = !yukari;
  }
}

const MASKELER = [
  (x, y) => (x + y) % 2 === 0,
  (x, y) => y % 2 === 0,
  (x) => x % 3 === 0,
  (x, y) => (x + y) % 3 === 0,
  (x, y) => (Math.floor(y / 2) + Math.floor(x / 3)) % 2 === 0,
  (x, y) => ((x * y) % 2) + ((x * y) % 3) === 0,
  (x, y) => (((x * y) % 2) + ((x * y) % 3)) % 2 === 0,
  (x, y) => (((x + y) % 2) + ((x * y) % 3)) % 2 === 0,
];

function maskeUygula(m, no) {
  const f = MASKELER[no];
  for (let y = 0; y < m.boyut; y++) {
    for (let x = 0; x < m.boyut; x++) {
      if (!m.islev[y][x] && f(x, y)) m.modul[y][x] ^= 1;
    }
  }
}

/** Biçim bilgisi: 5 bit veri + BCH(15,5), 0x5412 ile maskelenir */
function bicimBitleri(seviye, maske) {
  let veri = (SEVIYE_BIT[seviye] << 3) | maske;
  let bch = veri;
  for (let i = 0; i < 10; i++) bch = (bch << 1) ^ ((bch >>> 9) * 0x537);
  return (((veri << 10) | bch) ^ 0x5412) & 0x7fff;
}

function bicimYaz(m, seviye, maske) {
  const bitler = bicimBitleri(seviye, maske);
  const b = m.boyut;
  const al = (i) => (bitler >>> i) & 1;

  // Birinci kopya: 0–8. bitler sol üstteki 8. sütunda yukarıdan aşağı,
  // 9–14. bitler 8. satırda sağdan sola. Sıra standartta böyle; satır ve
  // sütunu karıştırmak okunabilir ama yanlış çözülen bir kod üretir.
  for (let i = 0; i <= 5; i++) m.modul[i][8] = al(i);
  m.modul[7][8] = al(6);
  m.modul[8][8] = al(7);
  m.modul[8][7] = al(8);
  for (let i = 9; i < 15; i++) m.modul[8][14 - i] = al(i);

  // İkinci kopya: 0–7. bitler 8. satırın sağ ucunda, 8–14. bitler 8. sütunun
  // alt ucunda.
  for (let i = 0; i < 8; i++) m.modul[8][b - 1 - i] = al(i);
  for (let i = 8; i < 15; i++) m.modul[b - 15 + i][8] = al(i);
}

/** Sürüm bilgisi (7 ve üstü): 6 bit veri + BCH(18,6) */
function surumYaz(m, surum) {
  if (surum < 7) return;
  let bch = surum;
  for (let i = 0; i < 12; i++) bch = (bch << 1) ^ ((bch >>> 11) * 0x1f25);
  const bitler = (surum << 12) | bch;
  const b = m.boyut;
  for (let i = 0; i < 18; i++) {
    const deger = (bitler >>> i) & 1;
    const a = Math.floor(i / 3);
    const c = (i % 3) + b - 11;
    m.modul[c][a] = deger;
    m.modul[a][c] = deger;
  }
}

/* ------------------------------------------------------- maske puanlama */

function ceza(m) {
  const b = m.boyut;
  let puan = 0;

  // 1: aynı renkte beşten uzun diziler
  for (let y = 0; y < b; y++) {
    for (const dikey of [false, true]) {
      let onceki = -1;
      let uzunluk = 0;
      for (let x = 0; x < b; x++) {
        const deger = dikey ? m.modul[x][y] : m.modul[y][x];
        if (deger === onceki) {
          uzunluk++;
          if (uzunluk === 5) puan += 3;
          else if (uzunluk > 5) puan += 1;
        } else {
          onceki = deger;
          uzunluk = 1;
        }
      }
    }
  }

  // 2: 2×2 tek renk bloklar
  for (let y = 0; y < b - 1; y++) {
    for (let x = 0; x < b - 1; x++) {
      const d = m.modul[y][x];
      if (d === m.modul[y][x + 1] && d === m.modul[y + 1][x] && d === m.modul[y + 1][x + 1]) puan += 3;
    }
  }

  // 3: bulucu desenine benzeyen 1:1:3:1:1 dizileri
  const desen = [1, 0, 1, 1, 1, 0, 1];
  const bosluk = [0, 0, 0, 0];
  const eslesir = (al) => {
    for (let i = 0; i + 6 < b; i++) {
      let tam = true;
      for (let j = 0; j < 7; j++) if (al(i + j) !== desen[j]) { tam = false; break; }
      if (!tam) continue;
      const oncesi = bosluk.every((_, k) => (i - 1 - k < 0 ? true : al(i - 1 - k) === 0));
      const sonrasi = bosluk.every((_, k) => (i + 7 + k >= b ? true : al(i + 7 + k) === 0));
      if (oncesi || sonrasi) puan += 40;
    }
  };
  for (let y = 0; y < b; y++) eslesir((x) => m.modul[y][x]);
  for (let x = 0; x < b; x++) eslesir((y) => m.modul[y][x]);

  // 4: koyu modül oranının %50'den sapması
  let koyu = 0;
  for (let y = 0; y < b; y++) for (let x = 0; x < b; x++) koyu += m.modul[y][x];
  const oran = (koyu * 100) / (b * b);
  puan += Math.floor(Math.abs(oran - 50) / 5) * 10;
  return puan;
}

/* -------------------------------------------------------------- dışarıya */

/**
 * İşlev modüllerinin haritası (1 = desen, 0 = veri alanı). Çözümleyici testi
 * yerleşimi bu haritayla geri okuyor; üretim kodunda kullanılmıyor.
 */
export function islevHaritasi(surum) {
  const m = bosMatris(17 + 4 * surum);
  islevDesenleri(m, surum);
  return m.islev;
}

/** Sürüm başına toplam kod sözcüğü — tabloyla karşılaştırmalı test için. */
export const TOPLAM_KOD = TOPLAM;

/** Metni sığdıran en küçük sürümü seçer. */
export function surumSec(metin, seviye) {
  const uzunluk = baytlar(metin).length;
  for (let v = 1; v <= EN_BUYUK_SURUM; v++) {
    const bas = 4 + (v < 10 ? 8 : 16);
    if (veriKapasitesi(v, seviye) * 8 >= bas + uzunluk * 8) return v;
  }
  return null;
}

/**
 * @param {string} metin
 * @param {{seviye?: 'L'|'M'|'Q'|'H', maske?: number}} [secenek]
 *   `maske` verilirse o desen kullanılır (test ve karşılaştırma için);
 *   verilmezse sekiz maske denenip ceza puanı en düşük olan seçilir.
 * @returns {{modul: Uint8Array[], boyut: number, surum: number, seviye: string, maske: number}}
 */
export function qrUret(metin, secenek = {}) {
  const seviye = secenek.seviye ?? 'M';
  if (!EC_KOD[seviye]) throw new Error('Bilinmeyen hata düzeltme seviyesi.');
  const surum = surumSec(metin, seviye);
  if (!surum) throw new Error('Metin bu araç için fazla uzun (sürüm 10 sınırı).');

  const akis = kodAkisi(bitDizisi(baytlar(metin), surum, seviye), surum, seviye);

  const denenecek =
    secenek.maske === undefined ? [0, 1, 2, 3, 4, 5, 6, 7] : [secenek.maske];

  let enIyi = null;
  for (const maske of denenecek) {
    const m = bosMatris(17 + 4 * surum);
    islevDesenleri(m, surum);
    surumYaz(m, surum);
    veriYerlestir(m, akis);
    maskeUygula(m, maske);
    bicimYaz(m, seviye, maske);
    const puan = ceza(m);
    if (!enIyi || puan < enIyi.puan) enIyi = { m, puan, maske };
  }

  return { modul: enIyi.m.modul, boyut: enIyi.m.boyut, surum, seviye, maske: enIyi.maske };
}

/** WIFI: yükü — ayrılmış karakterler ters eğik çizgiyle kaçırılır */
export function wifiYuku({ ssid, parola = '', sifreleme = 'WPA', gizli = false }) {
  const kacir = (m) => String(m).replace(/([\\;,:"])/g, '\\$1');
  const tur = sifreleme === 'yok' ? 'nopass' : sifreleme;
  const parcalar = [`T:${tur}`, `S:${kacir(ssid)}`];
  if (tur !== 'nopass') parcalar.push(`P:${kacir(parola)}`);
  if (gizli) parcalar.push('H:true');
  return `WIFI:${parcalar.join(';')};;`;
}
