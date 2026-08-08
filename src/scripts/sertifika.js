/**
 * PEM sertifika okuyucu — DER/ASN.1 ayrıştırması ve X.509 alanları.
 *
 * Amaç sertifikayı doğrulamak değil, içindekini okunur hâle getirmek: kim için
 * verilmiş, ne zaman doluyor, hangi adları kapsıyor, anahtarı kaç bit. Bunun
 * için sunucuya yüklemeye gerek yok; ayrıştırma tarayıcıda yapılır.
 */

/* ------------------------------------------------------------ DER okuyucu */

/** Bir TLV (tag-length-value) düğümünü okur. */
function dugumOku(bayt, konum) {
  const etiket = bayt[konum];
  let p = konum + 1;
  let uzunluk = bayt[p++];

  if (uzunluk & 0x80) {
    const baytSayisi = uzunluk & 0x7f;
    uzunluk = 0;
    for (let i = 0; i < baytSayisi; i++) uzunluk = uzunluk * 256 + bayt[p++];
  }
  return { etiket, bas: p, son: p + uzunluk, uzunluk, sonrasi: p + uzunluk };
}

/** Yapısal (constructed) düğümün çocuklarını sırayla verir. */
function cocuklar(bayt, dugum) {
  const liste = [];
  let p = dugum.bas;
  while (p < dugum.son) {
    const c = dugumOku(bayt, p);
    liste.push(c);
    p = c.sonrasi;
  }
  return liste;
}

/** OID baytlarını "1.2.840.113549.1.1.11" biçimine çevirir. */
function oidCoz(bayt, dugum) {
  const parcalar = [];
  let ilk = bayt[dugum.bas];
  parcalar.push(Math.floor(ilk / 40), ilk % 40);
  let deger = 0;
  for (let i = dugum.bas + 1; i < dugum.son; i++) {
    const b = bayt[i];
    deger = deger * 128 + (b & 0x7f);
    if (!(b & 0x80)) {
      parcalar.push(deger);
      deger = 0;
    }
  }
  return parcalar.join('.');
}

const metinCoz = (bayt, dugum) => new TextDecoder().decode(bayt.subarray(dugum.bas, dugum.son));

/** UTCTime (YYMMDDHHMMSSZ) ve GeneralizedTime (YYYYMMDD…) */
function zamanCoz(bayt, dugum) {
  const m = metinCoz(bayt, dugum);
  const p = dugum.etiket === 0x17 ? '20' + m.slice(0, 2) : m.slice(0, 4);
  const g = dugum.etiket === 0x17 ? m.slice(2) : m.slice(4);
  return new Date(
    Date.UTC(
      Number(p),
      Number(g.slice(0, 2)) - 1,
      Number(g.slice(2, 4)),
      Number(g.slice(4, 6)),
      Number(g.slice(6, 8)),
      Number(g.slice(8, 10) || 0)
    )
  );
}

/* ------------------------------------------------------------ X.509 sözlük */

const OID_AD = {
  '2.5.4.3': 'CN',
  '2.5.4.6': 'C',
  '2.5.4.7': 'L',
  '2.5.4.8': 'ST',
  '2.5.4.10': 'O',
  '2.5.4.11': 'OU',
  '1.2.840.113549.1.9.1': 'E',
};

const OID_IMZA = {
  '1.2.840.113549.1.1.5': 'SHA-1 / RSA',
  '1.2.840.113549.1.1.11': 'SHA-256 / RSA',
  '1.2.840.113549.1.1.12': 'SHA-384 / RSA',
  '1.2.840.113549.1.1.13': 'SHA-512 / RSA',
  '1.2.840.113549.1.1.10': 'RSASSA-PSS',
  '1.2.840.10045.4.3.2': 'SHA-256 / ECDSA',
  '1.2.840.10045.4.3.3': 'SHA-384 / ECDSA',
};

const OID_ANAHTAR = {
  '1.2.840.113549.1.1.1': 'RSA',
  '1.2.840.10045.2.1': 'EC',
  '1.3.101.112': 'Ed25519',
};

const OID_KULLANIM = {
  '1.3.6.1.5.5.7.3.1': 'Sunucu kimlik doğrulama',
  '1.3.6.1.5.5.7.3.2': 'İstemci kimlik doğrulama',
  '1.3.6.1.5.5.7.3.3': 'Kod imzalama',
  '1.3.6.1.5.5.7.3.4': 'E-posta koruma',
  '1.3.6.1.5.5.7.3.8': 'Zaman damgası',
  '1.3.6.1.5.5.7.3.9': 'OCSP imzalama',
};

/** RDN dizisini { CN: '...', O: '...' } nesnesine çevirir. */
function adCoz(bayt, dugum) {
  const sonuc = {};
  const sira = [];
  for (const rdn of cocuklar(bayt, dugum)) {
    for (const ciftDugum of cocuklar(bayt, rdn)) {
      const [oidDugum, degerDugum] = cocuklar(bayt, ciftDugum);
      const ad = OID_AD[oidCoz(bayt, oidDugum)];
      if (!ad) continue;
      const deger = metinCoz(bayt, degerDugum);
      sonuc[ad] = sonuc[ad] ? `${sonuc[ad]}, ${deger}` : deger;
      sira.push(`${ad}=${deger}`);
    }
  }
  sonuc.metin = sira.join(', ');
  return sonuc;
}

/* -------------------------------------------------------------- dışarıya */

/** PEM gövdesini bayt dizisine çevirir; birden çok sertifika varsa hepsini verir. */
export function pemAyikla(metin) {
  const bloklar = [...metin.matchAll(/-----BEGIN CERTIFICATE-----([\s\S]*?)-----END CERTIFICATE-----/g)];
  if (!bloklar.length) throw new Error('PEM bloğu bulunamadı: -----BEGIN CERTIFICATE----- ile başlamalı.');
  return bloklar.map((b) => {
    const temiz = b[1].replace(/\s+/g, '');
    const ikili = atob(temiz);
    return Uint8Array.from(ikili, (c) => c.charCodeAt(0));
  });
}

/**
 * @returns {{konu:object, veren:object, seriNo:string, baslangic:Date, bitis:Date,
 *   imzaAlgoritmasi:string, anahtar:{tur:string, bit:number|null},
 *   adlar:string[], kullanim:string[], caMi:boolean, kendindenImzali:boolean}}
 */
export function sertifikaOku(der) {
  const kok = dugumOku(der, 0);
  const [tbs, imzaAlg] = cocuklar(der, kok);
  const tbsCocuk = cocuklar(der, tbs);

  // [0] sürüm etiketi isteğe bağlı; varsa alanlar bir kayar
  let i = 0;
  let surum = 1;
  if (tbsCocuk[0].etiket === 0xa0) {
    const s = cocuklar(der, tbsCocuk[0])[0];
    surum = der[s.bas] + 1;
    i = 1;
  }

  const seriDugum = tbsCocuk[i++];
  const seriNo = [...der.subarray(seriDugum.bas, seriDugum.son)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join(':');

  i++; // imza algoritması (tbs içinde tekrar eder)
  const veren = adCoz(der, tbsCocuk[i++]);
  const gecerlilik = cocuklar(der, tbsCocuk[i++]);
  const konu = adCoz(der, tbsCocuk[i++]);
  const anahtarBilgi = tbsCocuk[i++];

  /* --- açık anahtar ---------------------------------------------------- */
  const [algDugum, bitDizisi] = cocuklar(der, anahtarBilgi);
  const anahtarTur = OID_ANAHTAR[oidCoz(der, cocuklar(der, algDugum)[0])] ?? 'bilinmeyen';
  let anahtarBit = null;
  if (anahtarTur === 'RSA') {
    // BIT STRING'in ilk baytı kullanılmayan bit sayısı; sonrası RSAPublicKey
    const ic = dugumOku(der, bitDizisi.bas + 1);
    const modul = cocuklar(der, ic)[0];
    let uzunluk = modul.uzunluk;
    if (der[modul.bas] === 0) uzunluk -= 1; // başta işaret baytı
    anahtarBit = uzunluk * 8;
  } else if (anahtarTur === 'EC') {
    const egri = cocuklar(der, algDugum)[1];
    const oid = egri ? oidCoz(der, egri) : '';
    anahtarBit = { '1.2.840.10045.3.1.7': 256, '1.3.132.0.34': 384, '1.3.132.0.35': 521 }[oid] ?? null;
  }

  /* --- uzantılar -------------------------------------------------------- */
  const adlar = [];
  const kullanim = [];
  let caMi = false;

  const uzantiKap = tbsCocuk.slice(i).find((d) => d.etiket === 0xa3);
  if (uzantiKap) {
    const dizi = cocuklar(der, uzantiKap)[0];
    for (const uzanti of cocuklar(der, dizi)) {
      const parcalar = cocuklar(der, uzanti);
      const oid = oidCoz(der, parcalar[0]);
      const govdeDugum = parcalar[parcalar.length - 1];
      const icerik = dugumOku(der, govdeDugum.bas);

      if (oid === '2.5.29.17') {
        // subjectAltName
        for (const ad of cocuklar(der, icerik)) {
          if (ad.etiket === 0x82) adlar.push(metinCoz(der, ad)); // dNSName
          else if (ad.etiket === 0x87) {
            const b = der.subarray(ad.bas, ad.son);
            adlar.push(b.length === 4 ? [...b].join('.') : '[IPv6]');
          }
        }
      } else if (oid === '2.5.29.19') {
        // basicConstraints
        const ic = cocuklar(der, icerik);
        caMi = ic.length > 0 && ic[0].etiket === 0x01 && der[ic[0].bas] !== 0;
      } else if (oid === '2.5.29.37') {
        // extendedKeyUsage
        for (const k of cocuklar(der, icerik)) {
          const kOid = oidCoz(der, k);
          kullanim.push(OID_KULLANIM[kOid] ?? kOid);
        }
      }
    }
  }

  return {
    surum,
    seriNo,
    veren,
    konu,
    baslangic: zamanCoz(der, gecerlilik[0]),
    bitis: zamanCoz(der, gecerlilik[1]),
    imzaAlgoritmasi: OID_IMZA[oidCoz(der, cocuklar(der, imzaAlg)[0])] ?? oidCoz(der, cocuklar(der, imzaAlg)[0]),
    anahtar: { tur: anahtarTur, bit: anahtarBit },
    adlar,
    kullanim,
    caMi,
    kendindenImzali: veren.metin === konu.metin,
  };
}

/** Kalan gün ve durum sınıfı — arayüzün rengi buradan geliyor. */
export function kalanGun(bitis, simdi = new Date()) {
  return Math.floor((bitis.getTime() - simdi.getTime()) / 86400000);
}
