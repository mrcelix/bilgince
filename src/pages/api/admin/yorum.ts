import type { APIRoute } from 'astro';
import { ANAHTAR, kv, kvBoru, kvKurulu } from '../../../admin/kv';

// Middleware bu yolu koruyor: oturumsuz istek 401 alır.
export const prerender = false;

const json = (govde: unknown, durum = 200) =>
  new Response(JSON.stringify(govde), {
    status: durum,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

/** Upstash HGETALL düz dizi döndürür: [alan, değer, alan, değer…] */
function hashCoz(ham: unknown): any[] {
  const dizi = Array.isArray(ham) ? ham : [];
  const sonuc: any[] = [];
  for (let i = 1; i < dizi.length; i += 2) {
    try {
      sonuc.push(JSON.parse(dizi[i] as string));
    } catch {
      /* bozuk kayıt atlanır */
    }
  }
  return sonuc;
}

/* -------------------------------------------------------------------- GET */

export const GET: APIRoute = async () => {
  if (!kvKurulu()) return json({ kurulu: false, bekleyen: [], onayli: [] });

  try {
    const yollar = await kv<string[]>(['SMEMBERS', ANAHTAR.yollar]);
    const komutlar = [['HGETALL', ANAHTAR.bekleyen], ...(yollar ?? []).map((y) => ['HGETALL', ANAHTAR.onayli(y)])];
    const sonuclar = await kvBoru<any[]>(komutlar as any);

    const bekleyen = hashCoz(sonuclar[0]).sort((a, b) => String(b.tarih).localeCompare(String(a.tarih)));
    const onayli = (yollar ?? [])
      .flatMap((yol, i) => hashCoz(sonuclar[i + 1]).map((y) => ({ ...y, yol: y.yol ?? yol })))
      .sort((a, b) => String(b.tarih).localeCompare(String(a.tarih)));

    return json({ kurulu: true, bekleyen, onayli });
  } catch (e) {
    return json({ hata: e instanceof Error ? e.message : 'Yorumlar okunamadı.' }, 502);
  }
};

/* ------------------------------------------------------------------- POST */

export const POST: APIRoute = async ({ request }) => {
  if (!kvKurulu()) return json({ hata: 'Yorum deposu yapılandırılmamış.' }, 503);

  let govde: Record<string, any>;
  try {
    govde = await request.json();
  } catch {
    return json({ hata: 'Gövde okunamadı.' }, 400);
  }

  const { islem, id, yol } = govde;
  if (!id || typeof id !== 'string') return json({ hata: 'id gerekli.' }, 400);

  try {
    if (islem === 'onayla') {
      const ham = await kv<string | null>(['HGET', ANAHTAR.bekleyen, id]);
      if (!ham) return json({ hata: 'Bekleyen yorum bulunamadı.' }, 404);
      const kayit = JSON.parse(ham);
      kayit.onayTarihi = new Date().toISOString();

      await kvBoru([
        ['HSET', ANAHTAR.onayli(kayit.yol), id, JSON.stringify(kayit)],
        ['SADD', ANAHTAR.yollar, kayit.yol],
        ['HDEL', ANAHTAR.bekleyen, id],
      ] as any);
      return json({ tamam: true, yol: kayit.yol });
    }

    if (islem === 'reddet') {
      await kv(['HDEL', ANAHTAR.bekleyen, id]);
      return json({ tamam: true });
    }

    if (islem === 'sil') {
      if (typeof yol !== 'string') return json({ hata: 'yol gerekli.' }, 400);
      await kv(['HDEL', ANAHTAR.onayli(yol), id]);
      // Sayfada onaylı yorum kalmadıysa yol listesinden de düşür
      const kalan = await kv<number>(['HLEN', ANAHTAR.onayli(yol)]);
      if (!Number(kalan)) await kv(['SREM', ANAHTAR.yollar, yol]);
      return json({ tamam: true });
    }

    if (islem === 'yanit') {
      if (typeof yol !== 'string') return json({ hata: 'yol gerekli.' }, 400);
      const ham = await kv<string | null>(['HGET', ANAHTAR.onayli(yol), id]);
      if (!ham) return json({ hata: 'Yorum bulunamadı.' }, 404);
      const kayit = JSON.parse(ham);
      const yanit = String(govde.yanit ?? '').trim();
      kayit.yanit = yanit ? { metin: yanit.slice(0, 1500), tarih: new Date().toISOString() } : null;
      await kv(['HSET', ANAHTAR.onayli(yol), id, JSON.stringify(kayit)]);
      return json({ tamam: true });
    }

    return json({ hata: 'Bilinmeyen işlem.' }, 400);
  } catch (e) {
    return json({ hata: e instanceof Error ? e.message : 'İşlem yapılamadı.' }, 502);
  }
};
