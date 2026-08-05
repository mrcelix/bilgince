import type { APIRoute } from 'astro';
import { lookup } from 'node:dns/promises';
import { isIP } from 'node:net';

// Keystatic gibi bu uç da sunucu tarafında çalışmalı: hedef siteyi tarayıcıdan
// çekmek CORS'a takılır, ayrıca SSRF denetimini istemciye bırakamayız.
export const prerender = false;

const ZAMAN_ASIMI = 8000;
const EN_BUYUK_GOVDE = 2 * 1024 * 1024; // 2 MB
const EN_COK_YONLENDIRME = 3;

/* --------------------------------------------------------------------------
   Güvenlik: yalnızca genel internete çıkılabilir
   -------------------------------------------------------------------------- */

/** RFC1918, loopback, link-local ve benzeri iç ağ blokları */
function ozelAdres(ip: string): boolean {
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

async function adresGuvenliMi(adres: URL): Promise<string | null> {
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
async function guvenliGetir(baslangic: URL, kabul: string) {
  let su = baslangic;
  for (let adim = 0; adim <= EN_COK_YONLENDIRME; adim++) {
    const hata = await adresGuvenliMi(su);
    if (hata) throw new Error(hata);

    const cevap = await fetch(su, {
      redirect: 'manual',
      signal: AbortSignal.timeout(ZAMAN_ASIMI),
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
async function metniOku(cevap: Response, sinir = EN_BUYUK_GOVDE): Promise<string> {
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

/* --------------------------------------------------------------------------
   HTML ayrıştırma — tam bir ayrıştırıcı yerine hedefli desenler
   -------------------------------------------------------------------------- */

function etiketCoz(ham: string): string {
  return ham
    .replace(/&(#\d+|#x[0-9a-f]+|[a-z]+);/gi, (tam, kod) => {
      if (kod[0] === '#') {
        const n = kod[1] === 'x' || kod[1] === 'X' ? parseInt(kod.slice(2), 16) : parseInt(kod.slice(1), 10);
        return Number.isFinite(n) ? String.fromCodePoint(n) : tam;
      }
      const harita: Record<string, string> = {
        amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', hellip: '…',
        ndash: '–', mdash: '—', rsquo: '’', lsquo: '‘', ldquo: '“', rdquo: '”',
      };
      return harita[kod.toLowerCase()] ?? tam;
    })
    .replace(/\s+/g, ' ')
    .trim();
}

function metaOku(html: string, ad: string): string | null {
  // name= ve property= sıralaması siteden siteye değişiyor, ikisini de dene
  const desenler = [
    new RegExp(`<meta[^>]+(?:name|property)=["']${ad}["'][^>]*content=["']([^"']*)["']`, 'i'),
    new RegExp(`<meta[^>]+content=["']([^"']*)["'][^>]*(?:name|property)=["']${ad}["']`, 'i'),
  ];
  for (const d of desenler) {
    const e = html.match(d);
    if (e?.[1]) return etiketCoz(e[1]);
  }
  return null;
}

/* --------------------------------------------------------------------------
   Renk çıkarımı
   -------------------------------------------------------------------------- */

type Hsl = { h: number; s: number; l: number };

function hexNormalle(h: string): string {
  const g = h.replace('#', '');
  if (g.length === 3) return '#' + g.split('').map((c) => c + c).join('').toLowerCase();
  if (g.length === 8) return '#' + g.slice(0, 6).toLowerCase();
  return '#' + g.toLowerCase();
}

function hexHsl(hex: string): Hsl {
  const s = hex.slice(1);
  const r = parseInt(s.slice(0, 2), 16) / 255;
  const g = parseInt(s.slice(2, 4), 16) / 255;
  const b = parseInt(s.slice(4, 6), 16) / 255;
  const enB = Math.max(r, g, b);
  const enK = Math.min(r, g, b);
  const l = (enB + enK) / 2;
  const d = enB - enK;
  if (d === 0) return { h: 0, s: 0, l };
  const sat = l > 0.5 ? d / (2 - enB - enK) : d / (enB + enK);
  let h: number;
  if (enB === r) h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
  else if (enB === g) h = ((b - r) / d + 2) / 6;
  else h = ((r - g) / d + 4) / 6;
  return { h: h * 360, s: sat, l };
}

function renkleriTopla(css: string): Map<string, number> {
  const sayac = new Map<string, number>();
  const ekle = (hex: string) => sayac.set(hex, (sayac.get(hex) ?? 0) + 1);

  for (const e of css.matchAll(/#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})\b/gi)) {
    ekle(hexNormalle(e[1]));
  }
  for (const e of css.matchAll(/rgba?\(\s*(\d+)[\s,]+(\d+)[\s,]+(\d+)/gi)) {
    const [r, g, b] = [e[1], e[2], e[3]].map((n) => Math.min(255, Number(n)));
    ekle('#' + [r, g, b].map((n) => n.toString(16).padStart(2, '0')).join(''));
  }
  return sayac;
}

/** Sıklık listesinden zemin / metin / vurgu rollerini tahmin eder. */
function paletCikar(sayac: Map<string, number>, temaRengi: string | null) {
  const liste = [...sayac.entries()]
    .map(([hex, adet]) => ({ hex, adet, ...hexHsl(hex) }))
    .sort((a, b) => b.adet - a.adet);

  const enSik = (kosul: (r: (typeof liste)[number]) => boolean) => liste.find(kosul)?.hex ?? null;

  // Vurgu: doygun ve orta parlaklıkta olan en sık renk.
  // theme-color yalnızca bu ölçütü karşılıyorsa öne alınır — birçok sitede o
  // değer tarayıcı çubuğu için seçilmiş koyu bir gövde rengidir, marka rengi değil.
  const vurguOlur = (r: Hsl) => r.s >= 0.25 && r.l >= 0.2 && r.l <= 0.72;
  const vurgular = liste.filter(vurguOlur);
  const temaUygun = temaRengi && vurguOlur(hexHsl(temaRengi)) ? temaRengi : null;
  const vurgu = temaUygun ?? vurgular[0]?.hex ?? '#3a45e0';

  // İkincil vurgu: birincisinden en az 40° uzak ton
  const vurguTon = hexHsl(vurgu).h;
  const uzak = vurgular.find((r) => {
    const fark = Math.abs(r.h - vurguTon);
    return Math.min(fark, 360 - fark) > 40;
  });

  return {
    vurgu,
    vurgu2: uzak?.hex ?? vurgu,
    zemin: enSik((r) => r.l >= 0.9) ?? '#ffffff',
    koyu: (temaRengi && hexHsl(temaRengi).l <= 0.3 ? temaRengi : null) ?? enSik((r) => r.l <= 0.22) ?? '#111827',
    hepsi: liste.slice(0, 12).map((r) => r.hex),
  };
}

/* --------------------------------------------------------------------------
   Site logosu
   -------------------------------------------------------------------------- */

const EN_BUYUK_LOGO = 512 * 1024;

/** rel=icon bağlantılarını boyuta göre sıralar; en büyüğü en iyisidir. */
function logoAdaylari(html: string, kok: URL): URL[] {
  const adaylar: { adres: URL; puan: number }[] = [];

  for (const e of html.matchAll(/<link[^>]+>/gi)) {
    const etiket = e[0];
    const rel = etiket.match(/rel=["']([^"']+)["']/i)?.[1]?.toLowerCase() ?? '';
    if (!/\b(apple-touch-icon|icon|shortcut icon|mask-icon)\b/.test(rel)) continue;

    const href = etiket.match(/href=["']([^"']+)["']/i)?.[1];
    if (!href || href.startsWith('data:')) continue;

    // "180x180" → 180. Belirtilmemişse apple-touch-icon genelde 180'dir.
    const olcu = Number(etiket.match(/sizes=["'](\d+)x\d+["']/i)?.[1] ?? 0);
    const puan = olcu || (rel.includes('apple') ? 180 : rel.includes('mask') ? 64 : 32);

    try {
      adaylar.push({ adres: new URL(href, kok), puan });
    } catch {
      // bozuk href
    }
  }

  // 512'den büyük ikonlar gereksiz; 64–256 arası ideal
  adaylar.sort((a, b) => Math.abs(180 - a.puan) - Math.abs(180 - b.puan));
  const siralı = adaylar.map((a) => a.adres);
  siralı.push(new URL('/favicon.ico', kok)); // hiçbiri yoksa kök favicon
  return siralı.slice(0, 3);
}

async function logoGetir(html: string, kok: URL): Promise<string | null> {
  for (const aday of logoAdaylari(html, kok)) {
    try {
      const { cevap } = await guvenliGetir(aday, 'image/*');
      const tur = cevap.headers.get('content-type') ?? '';
      if (!tur.startsWith('image/')) continue;

      const bayt = new Uint8Array(await cevap.arrayBuffer());
      if (!bayt.length || bayt.length > EN_BUYUK_LOGO) continue;

      let ikili = '';
      for (const b of bayt) ikili += String.fromCharCode(b);
      // Tuvalin kirlenmemesi için logoyu data URI olarak veriyoruz: favicon'lar
      // çoğu sitede CORS başlığı taşımaz, doğrudan yüklenirse indirme bozulurdu.
      return `data:${tur.split(';')[0]};base64,${btoa(ikili)}`;
    } catch {
      // sıradaki adaya geç
    }
  }
  return null;
}

/* --------------------------------------------------------------------------
   Uç nokta
   -------------------------------------------------------------------------- */

const json = (govde: unknown, durum = 200) =>
  new Response(JSON.stringify(govde), {
    status: durum,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      // aynı siteyi arka arkaya denemek yaygın; kısa bir önbellek yeterli
      'cache-control': durum === 200 ? 'public, max-age=300' : 'no-store',
    },
  });

export const GET: APIRoute = async ({ url }) => {
  const girdi = (url.searchParams.get('adres') ?? '').trim();
  if (!girdi) return json({ hata: 'Adres verilmedi.' }, 400);

  let hedef: URL;
  try {
    hedef = new URL(/^https?:\/\//i.test(girdi) ? girdi : `https://${girdi}`);
  } catch {
    return json({ hata: 'Adres okunamadı.' }, 400);
  }

  let html: string;
  let sonAdres: URL;
  try {
    const sonuc = await guvenliGetir(hedef, 'text/html,application/xhtml+xml');
    sonAdres = sonuc.sonAdres;
    html = await metniOku(sonuc.cevap);
  } catch (e) {
    const mesaj = e instanceof Error ? e.message : 'Site getirilemedi.';
    return json({ hata: mesaj.includes('timed out') ? 'Site zamanında yanıt vermedi.' : mesaj }, 502);
  }

  const kok = html.slice(0, 400_000);
  const baslikHam = kok.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] ?? '';

  const baslik =
    metaOku(kok, 'og:title') ?? metaOku(kok, 'twitter:title') ?? etiketCoz(baslikHam) ?? sonAdres.hostname;
  const aciklama =
    metaOku(kok, 'og:description') ?? metaOku(kok, 'description') ?? metaOku(kok, 'twitter:description') ?? '';
  const siteAdi = metaOku(kok, 'og:site_name') ?? sonAdres.hostname.replace(/^www\./, '');
  const temaRengi = metaOku(kok, 'theme-color');

  // Stil kaynakları: satır içi <style> blokları + aynı kaynaktaki ilk iki CSS
  let css = [...kok.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/gi)].map((e) => e[1]).join('\n');

  const stilAdresleri = [...kok.matchAll(/<link[^>]+rel=["']?stylesheet["']?[^>]*>/gi)]
    .map((e) => e[0].match(/href=["']([^"']+)["']/i)?.[1])
    .filter((h): h is string => Boolean(h))
    .map((h) => {
      try {
        return new URL(h, sonAdres);
      } catch {
        return null;
      }
    })
    .filter((u): u is URL => u !== null && u.origin === sonAdres.origin)
    .slice(0, 2);

  for (const stil of stilAdresleri) {
    try {
      const { cevap } = await guvenliGetir(stil, 'text/css');
      css += '\n' + (await metniOku(cevap, 300 * 1024));
    } catch {
      // tek bir stil dosyası alınamazsa analiz yine de sürer
    }
  }

  const palet = paletCikar(renkleriTopla(css), temaRengi && /^#/.test(temaRengi) ? hexNormalle(temaRengi) : null);
  const logo = await logoGetir(kok, sonAdres);

  return json({
    logo,
    adres: sonAdres.href,
    alan: sonAdres.hostname.replace(/^www\./, ''),
    siteAdi,
    baslik: baslik.slice(0, 160),
    aciklama: aciklama.slice(0, 320),
    gorsel: metaOku(kok, 'og:image') ?? metaOku(kok, 'twitter:image') ?? null,
    palet,
    stilSayisi: stilAdresleri.length,
  });
};
