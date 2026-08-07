// Dış siteye çıkan uçların (tema analizi, site görüntüsü) ortak güvenlik katmanı.
// Kullanıcıdan gelen bir adresi getirmeden önce her yönlendirme adımı ayrı ayrı
// doğrulanır; aksi hâlde tek bir 302 ile iç ağa ya da bulut meta veri ucuna
// yönlendirilebiliriz.

import { lookup } from 'node:dns/promises';
import { isIP } from 'node:net';

const VARSAYILAN_ZAMAN_ASIMI = 8000;
const VARSAYILAN_YONLENDIRME = 3;
const VARSAYILAN_GOVDE = 2 * 1024 * 1024; // 2 MB

/** RFC1918, loopback, link-local ve benzeri iç ağ blokları */
export function ozelAdres(ip: string): boolean {
  if (isIP(ip) === 6) {
    const d = ip.toLowerCase();
    if (d === '::1' || d === '::') return true;
    if (d.startsWith('fe80') || d.startsWith('fc') || d.startsWith('fd')) return true;
    // IPv4 eşlemeli IPv6: ::ffff:10.0.0.1
    const esleme = d.match(/::ffff:(\d+\.\d+\.\d+\.\d+)$/);
    return esleme ? ozelAdres(esleme[1]) : false;
  }

  const [a, b] = ip.split('.').map(Number);
  if (a === 10 || a === 127 || a === 0) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a === 192 && b === 168) return true;
  if (a === 169 && b === 254) return true; // bulut meta veri uçları burada
  if (a === 100 && b >= 64 && b <= 127) return true;
  return false;
}

/** Adres genel internete mi çıkıyor? Sorun varsa Türkçe hata metni döner. */
export async function adresGuvenliMi(adres: URL): Promise<string | null> {
  if (adres.protocol !== 'http:' && adres.protocol !== 'https:') {
    return 'Yalnızca http ve https adresleri desteklenir.';
  }
  const ad = adres.hostname.replace(/^\[|\]$/g, '');
  if (ad === 'localhost' || ad.endsWith('.localhost') || ad.endsWith('.internal')) {
    return 'İç ağ adresleri çözümlenemez.';
  }
  if (isIP(ad)) {
    return ozelAdres(ad) ? 'İç ağ adresleri çözümlenemez.' : null;
  }
  try {
    const kayitlar = await lookup(ad, { all: true });
    if (kayitlar.some((k) => ozelAdres(k.address))) {
      return 'İç ağ adresleri çözümlenemez.';
    }
  } catch {
    return 'Alan adı çözümlenemedi.';
  }
  return null;
}

/** Her yönlendirme adımını ayrı ayrı doğrulayarak getirir. */
export async function guvenliGetir(
  baslangic: URL,
  kabul: string,
  secenek: { zamanAsimi?: number; enCokYonlendirme?: number } = {}
) {
  const zamanAsimi = secenek.zamanAsimi ?? VARSAYILAN_ZAMAN_ASIMI;
  const enCokYonlendirme = secenek.enCokYonlendirme ?? VARSAYILAN_YONLENDIRME;

  let su = baslangic;
  for (let adim = 0; adim <= enCokYonlendirme; adim++) {
    const hata = await adresGuvenliMi(su);
    if (hata) throw new Error(hata);

    const cevap = await fetch(su, {
      redirect: 'manual',
      signal: AbortSignal.timeout(zamanAsimi),
      headers: {
        accept: kabul,
        'accept-language': 'tr,en;q=0.8',
        'user-agent': 'bilgince-paylasim-karti/1.0 (+https://www.bilgince.com/araclar/paylasim-karti)',
      },
    });

    if (cevap.status >= 300 && cevap.status < 400) {
      const hedef = cevap.headers.get('location');
      if (!hedef) throw new Error('Yönlendirme hedefi okunamadı.');
      su = new URL(hedef, su);
      continue;
    }
    if (!cevap.ok) throw new Error(`Sunucu ${cevap.status} döndürdü.`);
    return { cevap, sonAdres: su };
  }
  throw new Error('Çok fazla yönlendirme.');
}

/** Gövdeyi üst sınıra kadar okur; dev dosyalarda belleği korur. */
export async function metniOku(cevap: Response, sinir = VARSAYILAN_GOVDE): Promise<string> {
  const govde = cevap.body;
  if (!govde) return '';
  const okuyucu = govde.getReader();
  const cozucu = new TextDecoder('utf-8');
  let metin = '';
  let bayt = 0;
  while (bayt < sinir) {
    const { done, value } = await okuyucu.read();
    if (done) break;
    bayt += value.byteLength;
    metin += cozucu.decode(value, { stream: true });
  }
  await okuyucu.cancel().catch(() => {});
  return metin;
}
