/**
 * Saha çantası — ortak mantık.
 *
 * Çanta yalnızca kimlik listesi tutar; içerik `/canta.json` dizininden gelir.
 * Böylece paylaşım bağlantısı kısa kalır ve her sayfa aynı veriyi kullanır.
 *
 * Depolama localStorage; adreste `?canta=` varsa o öncelikli — paylaşılan bir
 * bağlantı açıldığında karşıdakinin çantasını görürsünüz, kendi çantanız
 * ezilmez (birleştirme kararını kullanıcı verir).
 */

const ANAHTAR = 'canta';
const OLAY = 'canta-degisti';

/** @returns {string[]} kimlik listesi */
export function oku() {
  try {
    const ham = localStorage.getItem(ANAHTAR);
    const dizi = ham ? JSON.parse(ham) : [];
    return Array.isArray(dizi) ? dizi.filter((k) => typeof k === 'string') : [];
  } catch {
    return [];
  }
}

export function yaz(kimlikler) {
  try {
    localStorage.setItem(ANAHTAR, JSON.stringify(kimlikler));
  } catch {
    /* gizli sekmede yazma engellenebilir; sayfa yine çalışsın */
  }
  dispatchEvent(new CustomEvent(OLAY, { detail: kimlikler }));
}

export function ekle(kimlik) {
  const simdiki = oku();
  if (simdiki.includes(kimlik)) return simdiki;
  const yeni = [...simdiki, kimlik];
  yaz(yeni);
  return yeni;
}

export function cikar(kimlik) {
  const yeni = oku().filter((k) => k !== kimlik);
  yaz(yeni);
  return yeni;
}

export function icindeMi(kimlik) {
  return oku().includes(kimlik);
}

export function bosalt() {
  yaz([]);
}

/** Kimliği bir adım yukarı/aşağı taşır. */
export function tasi(kimlik, yon) {
  const dizi = oku();
  const i = dizi.indexOf(kimlik);
  const j = i + yon;
  if (i === -1 || j < 0 || j >= dizi.length) return dizi;
  [dizi[i], dizi[j]] = [dizi[j], dizi[i]];
  yaz(dizi);
  return dizi;
}

export function degisince(islev) {
  addEventListener(OLAY, (e) => islev(e.detail ?? oku()));
  // Başka sekmede değişirse burada da görünsün
  addEventListener('storage', (e) => {
    if (e.key === ANAHTAR) islev(oku());
  });
}

/* --- içerik dizini ------------------------------------------------------- */

let dizinSozu = null;

/** Dizini bir kez indirir; kimlik → öğe eşlemi döner. */
export function dizin() {
  if (!dizinSozu) {
    dizinSozu = fetch('/canta.json')
      .then((c) => {
        if (!c.ok) throw new Error('dizin okunamadı');
        return c.json();
      })
      .then((d) => new Map(d.ogeler.map((o) => [o.kimlik, o])));
    dizinSozu.catch(() => {
      dizinSozu = null; // sonraki denemede yeniden kurulsun
    });
  }
  return dizinSozu;
}

/** Adresteki ?canta= listesi — paylaşılan çanta. */
export function adrestenOku() {
  const ham = new URLSearchParams(location.search).get(ANAHTAR);
  return ham ? ham.split(',').map((s) => s.trim()).filter(Boolean) : null;
}

export function paylasimAdresi(kimlikler) {
  const u = new URL('/canta', location.origin);
  u.searchParams.set(ANAHTAR, kimlikler.join(','));
  return u.href;
}
