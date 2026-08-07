import type { APIRoute } from 'astro';
import { adresGuvenliMi, guvenliGetir, metniOku } from '../../guvenli-adres';

// "Site önizleme" stili hedef sitenin görüntüsünü ister. İki kaynak var ve
// sıra önemlidir:
//   1. Cloudflare Browser Rendering — gerçek ekran görüntüsü (yapılandırılmışsa)
//   2. Sayfanın kendi og:image'i — her sitede var sayılmaz ama bedava ve hızlı
// İkisi de görsel gövdesi döndürür; hangisinin kullanıldığı `x-kaynak`
// başlığında bildirilir, istemci durum metnini ona göre yazar.
export const prerender = false;

const EKRAN_ZAMAN_ASIMI = 25000;
const EN_BUYUK_GORSEL = 6 * 1024 * 1024;

const json = (govde: unknown, durum: number) =>
  new Response(JSON.stringify(govde), {
    status: durum,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

const gorsel = (govde: BodyInit, tur: string, kaynak: 'ekran' | 'og') =>
  new Response(govde, {
    headers: {
      'content-type': tur,
      'x-kaynak': kaynak,
      // aynı siteyi stil değiştirirken tekrar tekrar istemek yaygın
      'cache-control': 'public, max-age=3600',
    },
  });

/* --------------------------------------------------------------------------
   1. Gerçek ekran görüntüsü — Cloudflare Browser Rendering
   -------------------------------------------------------------------------- */

async function ekranGoruntusu(hedef: URL): Promise<Response | null> {
  const hesap = import.meta.env.CLOUDFLARE_ACCOUNT_ID;
  // Ekran görüntüsü için ayrı bir jeton tanımlanabilir; tek jetonlu kurulumlarda
  // AI jetonu (Browser Rendering izni de verilmişse) kullanılır.
  const jeton = import.meta.env.CLOUDFLARE_TARAYICI_TOKEN || import.meta.env.CLOUDFLARE_AI_TOKEN;
  if (!hesap || !jeton) return null;

  try {
    const cevap = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${hesap}/browser-rendering/screenshot`,
      {
        method: 'POST',
        signal: AbortSignal.timeout(EKRAN_ZAMAN_ASIMI),
        headers: { authorization: `Bearer ${jeton}`, 'content-type': 'application/json' },
        body: JSON.stringify({
          url: hedef.href,
          // Masaüstü görünümü: kart içindeki tarayıcı çerçevesi bu oranı bekliyor
          viewport: { width: 1280, height: 800, deviceScaleFactor: 1 },
          screenshotOptions: { type: 'jpeg', quality: 85, fullPage: false },
          gotoOptions: { waitUntil: 'networkidle0', timeout: 20000 },
        }),
      }
    );

    const tur = cevap.headers.get('content-type') ?? '';
    if (cevap.ok && tur.startsWith('image/')) {
      return gorsel(await cevap.arrayBuffer(), tur.split(';')[0], 'ekran');
    }
    // Başarısızlıkta gövde JSON olur; sessizce og:image'e düşülür
    return null;
  } catch {
    return null;
  }
}

/* --------------------------------------------------------------------------
   2. Yedek — sayfanın kendi paylaşım görseli
   -------------------------------------------------------------------------- */

/** og:image / twitter:image adresini sayfanın kendi HTML'inden okur. */
function paylasimGorseli(html: string): string | null {
  for (const ad of ['og:image:secure_url', 'og:image', 'twitter:image', 'twitter:image:src']) {
    const desenler = [
      new RegExp(`<meta[^>]+(?:name|property)=["']${ad}["'][^>]*content=["']([^"']+)["']`, 'i'),
      new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]*(?:name|property)=["']${ad}["']`, 'i'),
    ];
    for (const d of desenler) {
      const e = html.match(d);
      if (e?.[1]) return e[1].replace(/&amp;/g, '&').trim();
    }
  }
  return null;
}

/**
 * Görseli sunucudan geçiriyoruz: doğrudan yüklenirse çoğu sitede CORS başlığı
 * olmadığı için tuval kirlenir ve PNG indirme bozulur. Adres istemciden değil
 * sayfanın kendi etiketinden geldiği için bu uç açık bir görsel vekili değil.
 */
async function ogGorseli(hedef: URL): Promise<Response | null> {
  try {
    const sayfa = await guvenliGetir(hedef, 'text/html,application/xhtml+xml');
    const html = (await metniOku(sayfa.cevap)).slice(0, 400_000);
    const ham = paylasimGorseli(html);
    if (!ham) return null;

    const adres = new URL(ham, sayfa.sonAdres);
    const { cevap } = await guvenliGetir(adres, 'image/*');
    const tur = cevap.headers.get('content-type') ?? '';
    if (!tur.startsWith('image/')) return null;

    const bayt = await cevap.arrayBuffer();
    if (!bayt.byteLength || bayt.byteLength > EN_BUYUK_GORSEL) return null;
    return gorsel(bayt, tur.split(';')[0], 'og');
  } catch {
    return null;
  }
}

/* --------------------------------------------------------------------------
   Uç nokta
   -------------------------------------------------------------------------- */

export const GET: APIRoute = async ({ url }) => {
  const girdi = (url.searchParams.get('adres') ?? '').trim();
  if (!girdi) return json({ hata: 'Adres verilmedi.' }, 400);

  let hedef: URL;
  try {
    hedef = new URL(/^https?:\/\//i.test(girdi) ? girdi : `https://${girdi}`);
  } catch {
    return json({ hata: 'Adres okunamadı.' }, 400);
  }

  const guvenlik = await adresGuvenliMi(hedef);
  if (guvenlik) return json({ hata: guvenlik }, 400);

  return (
    (await ekranGoruntusu(hedef)) ??
    (await ogGorseli(hedef)) ??
    json(
      {
        hata:
          'Bu sitenin görüntüsü alınamadı. Gerçek ekran görüntüsü için CLOUDFLARE_ACCOUNT_ID ve ' +
          'CLOUDFLARE_TARAYICI_TOKEN ortam değişkenleri gerekir; yedek olarak sayfanın og:image ' +
          'etiketi kullanılır, bu sitede o da yok.',
        yapilandirilmamis: !import.meta.env.CLOUDFLARE_ACCOUNT_ID,
      },
      502
    )
  );
};
