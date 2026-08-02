import type { APIRoute } from 'astro';

// Cloudflare API anahtarı istemciye sızmamalı; istek sunucudan çıkar.
export const prerender = false;

const MODEL = '@cf/black-forest-labs/flux-1-schnell';
const ZAMAN_ASIMI = 45000;

/**
 * İstem metinleri sunucuda sabittir. Kullanıcının yazdığı başlık/özet istemin
 * içine girmez: aksi hâlde araç, herkese açık bir "ne istersem çizdir" ucu
 * olurdu. Kart arka planı zaten soyut doku istediği için bu bir kısıt değil.
 */
const ISTEMLER: Record<string, string> = {
  neon: 'abstract neon cyberpunk background, glowing magenta and cyan light trails over a dark grid, volumetric haze, futuristic',
  doga: 'abstract organic nature background, layered emerald and moss green foliage shapes, soft morning light, botanical',
  okyanus: 'abstract ocean background, deep blue water surface with flowing wave patterns and light caustics, aerial view',
  altin: 'abstract luxury background, brushed gold and deep bronze gradient with elegant light rays, dark, premium',
  piksel: 'abstract retro pixel art background, chunky 8-bit blocks in purple magenta and lime, synthwave arcade aesthetic',
  suluboya: 'abstract watercolour background, soft lavender pink and pale blue washes bleeding into cream paper, delicate',
  steampunk: 'abstract steampunk background, weathered brass gears and riveted copper plates, warm sepia tones, industrial',
  galaksi: 'abstract deep space background, violet nebula clouds and distant stars, cosmic dust, dark and vast',
  anime: 'abstract anime sky background, pastel pink and blue gradient clouds with dramatic speed lines, cel shaded',
  minimal: 'abstract minimal background, off white paper texture with a single soft grey geometric curve, generous empty space',
  ates: 'abstract fire background, glowing embers and molten orange heat over deep charcoal, sparks rising',
  kristal: 'abstract crystal background, translucent ice facets refracting cyan and pale blue light, sharp geometric shards',
};

const ORTAK = 'wide banner composition, no text, no letters, no words, no watermark, no logo, no people';

/** Kartın altına metin gelecek: alt bölge sakin kalmalı. */
const KOMPOZISYON = 'visual interest concentrated in the upper half, lower half calm and uncluttered';

const renkAdi = (hex: string): string => {
  const n = parseInt(hex.slice(1), 16);
  const [r, g, b] = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((k) => k / 255);
  const enB = Math.max(r, g, b);
  const enK = Math.min(r, g, b);
  const l = (enB + enK) / 2;
  const d = enB - enK;
  if (d < 0.09) return l > 0.7 ? 'light grey' : l < 0.25 ? 'near black' : 'slate grey';
  let h = (enB === r ? (g - b) / d + (g < b ? 6 : 0) : enB === g ? (b - r) / d + 2 : (r - g) / d + 4) * 60;
  if (h < 0) h += 360;
  const adlar: [number, string][] = [
    [15, 'red'], [45, 'orange'], [70, 'amber'], [95, 'lime'], [150, 'green'],
    [190, 'teal'], [215, 'sky blue'], [255, 'blue'], [285, 'violet'],
    [320, 'magenta'], [360, 'crimson'],
  ];
  const ton = adlar.find(([sinir]) => h < sinir)?.[1] ?? 'blue';
  return `${l < 0.3 ? 'deep ' : l > 0.72 ? 'pale ' : ''}${ton}`;
};

const json = (govde: unknown, durum: number) =>
  new Response(JSON.stringify(govde), {
    status: durum,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

export const GET: APIRoute = async ({ url }) => {
  const hesap = import.meta.env.CLOUDFLARE_ACCOUNT_ID;
  const jeton = import.meta.env.CLOUDFLARE_AI_TOKEN;
  if (!hesap || !jeton) {
    return json(
      {
        hata:
          'AI arka plan bu kurulumda yapılandırılmamış. CLOUDFLARE_ACCOUNT_ID ve CLOUDFLARE_AI_TOKEN ' +
          'ortam değişkenleri tanımlandığında bu düğme çalışır.',
        yapilandirilmamis: true,
      },
      503
    );
  }

  const stil = url.searchParams.get('stil') ?? '';
  const tohum = Math.min(4294967295, Math.max(0, Number(url.searchParams.get('tohum')) || 1));
  const hexler = (url.searchParams.get('renkler') ?? '')
    .split(',')
    .filter((h) => /^#[0-9a-f]{6}$/i.test(h))
    .slice(0, 2);

  let istem = ISTEMLER[stil];
  if (!istem) {
    // "Site teması": paleti renk adlarına çevirip soyut bir zemin iste
    if (!hexler.length) return json({ hata: 'Bilinmeyen stil.' }, 400);
    istem = `abstract modern gradient background in ${hexler.map(renkAdi).join(' and ')}, smooth flowing shapes, clean corporate`;
  }

  try {
    const cevap = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${hesap}/ai/run/${MODEL}`,
      {
        method: 'POST',
        signal: AbortSignal.timeout(ZAMAN_ASIMI),
        headers: { authorization: `Bearer ${jeton}`, 'content-type': 'application/json' },
        body: JSON.stringify({ prompt: `${istem}, ${KOMPOZISYON}, ${ORTAK}`, steps: 6, seed: tohum }),
      }
    );

    const govde = await cevap.json();
    if (!cevap.ok) {
      const ilk = govde?.errors?.[0]?.message;
      return json({ hata: ilk ? `Cloudflare: ${ilk}` : `Cloudflare ${cevap.status} döndürdü.` }, 502);
    }

    // REST sarmalayıcısı sonucu result altına koyar; modelin kendi çıktısı düz gelir
    const b64: string | undefined = govde?.result?.image ?? govde?.image;
    if (!b64) return json({ hata: 'Model görsel döndürmedi.' }, 502);

    return new Response(Uint8Array.from(atob(b64), (c) => c.charCodeAt(0)), {
      headers: {
        'content-type': 'image/jpeg',
        // aynı stil + tohum aynı görseli verir, önbelleğe alınabilir
        'cache-control': 'public, max-age=86400',
      },
    });
  } catch (e) {
    const m = e instanceof Error ? e.message : '';
    return json({ hata: m.includes('timed out') ? 'Görsel üretimi zaman aşımına uğradı.' : 'Görsel üretilemedi.' }, 502);
  }
};
