import type { APIRoute } from 'astro';
import { guvenliGetir } from '../../guvenli-adres';

// Başlıkları tarayıcıdan okuyamıyoruz: CORS, yanıt başlıklarının çoğunu gizler.
// Bu yüzden istek sunucudan gidiyor; SSRF denetimi ortak katmanda.
export const prerender = false;

/** Yalnızca güvenlikle ilgili ve bilgi sızdıran başlıkları geri veriyoruz. */
const ILGILI = [
  'strict-transport-security',
  'content-security-policy',
  'content-security-policy-report-only',
  'x-content-type-options',
  'x-frame-options',
  'referrer-policy',
  'permissions-policy',
  'cross-origin-opener-policy',
  'cross-origin-resource-policy',
  'x-xss-protection',
  'server',
  'x-powered-by',
  'x-aspnet-version',
  'x-aspnetmvc-version',
  'set-cookie',
  'content-type',
];

const json = (govde: unknown, durum = 200) =>
  new Response(JSON.stringify(govde), {
    status: durum,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
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

  try {
    const { cevap, sonAdres } = await guvenliGetir(hedef, 'text/html,application/xhtml+xml');
    // Gövdeyi okumadan kapatıyoruz; bize yalnızca başlıklar gerekiyor
    cevap.body?.cancel().catch(() => {});

    const basliklar: Record<string, string> = {};
    for (const ad of ILGILI) {
      const deger = cevap.headers.get(ad);
      if (deger) basliklar[ad] = deger;
    }

    return json({
      adres: sonAdres.href,
      https: sonAdres.protocol === 'https:',
      durum: cevap.status,
      basliklar,
    });
  } catch (e) {
    const mesaj = e instanceof Error ? e.message : 'Adres getirilemedi.';
    return json({ hata: mesaj.includes('timed out') ? 'Site zamanında yanıt vermedi.' : mesaj }, 502);
  }
};
