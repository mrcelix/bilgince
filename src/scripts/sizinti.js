/**
 * Parola sızıntı kontrolü — Have I Been Pwned "Pwned Passwords" aralık ucu.
 *
 * k-anonimlik: parolanın SHA-1 özeti tarayıcıda hesaplanır, sunucuya yalnızca
 * özetin ilk 5 hanesi gider. Karşı taraf o ön eke uyan ~800 karmayı döndürür,
 * eşleşmeyi biz kendi tarafımızda yaparız. Parola da tam özeti de cihazdan
 * çıkmaz; HIBP hangi parolayı sorduğunuzu bilemez.
 */

const UC = 'https://api.pwnedpasswords.com/range/';

/** SHA-1 özeti, büyük harfli onaltılık — HIBP bu biçimi bekliyor. */
async function sha1Hex(metin) {
  if (!globalThis.crypto?.subtle) {
    throw new Error('Tarayıcı Web Crypto desteklemiyor (güvenli bağlam gerekir).');
  }
  const veri = new TextEncoder().encode(metin);
  const ozet = await crypto.subtle.digest('SHA-1', veri);
  return [...new Uint8Array(ozet)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
    .toUpperCase();
}

/**
 * @param {string} parola
 * @returns {Promise<{adet:number, onEk:string, aday:number}>}
 *   adet: parolanın sızıntı veri tabanında kaç kez göründüğü (0 = bulunamadı)
 *   aday: aynı ön eki paylaşan kaç karmanın döndüğü — k-anonimliğin ölçüsü
 */
export async function sizintiSay(parola) {
  const ozet = await sha1Hex(parola);
  const onEk = ozet.slice(0, 5);
  const kalan = ozet.slice(5);

  const cevap = await fetch(UC + onEk, { headers: { accept: 'text/plain' } });
  if (!cevap.ok) throw new Error(`Sızıntı servisi ${cevap.status} döndürdü.`);
  const govde = await cevap.text();

  let adet = 0;
  let aday = 0;
  for (const satir of govde.split('\n')) {
    const ayrac = satir.indexOf(':');
    if (ayrac < 0) continue;
    aday++;
    if (satir.slice(0, ayrac).trim().toUpperCase() === kalan) {
      adet = parseInt(satir.slice(ayrac + 1), 10) || 0;
    }
  }
  return { adet, onEk, aday };
}

/** Büyük sayıları okunur kılar: 12345 → "12.345" */
export const sayiBicim = (n) => new Intl.NumberFormat('tr-TR').format(n);
