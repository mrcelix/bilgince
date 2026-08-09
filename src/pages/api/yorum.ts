import type { APIRoute } from 'astro';
import { ANAHTAR, hizSiniri, kv, kvBoru, kvKurulu, parmakIzi } from '../../admin/kv';

// Sayfalar statik üretiliyor; yorumlar bu uçtan istemci tarafında yükleniyor.
export const prerender = false;

const json = (govde: unknown, durum = 200) =>
  new Response(JSON.stringify(govde), {
    status: durum,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

/** Yalnızca site içi yollar; dışarıdan gelen adresler kabul edilmiyor. */
function yolGecerliMi(yol: unknown): yol is string {
  return typeof yol === 'string' && /^\/[\w\-/.]{0,120}$/.test(yol) && !yol.includes('..');
}

/* -------------------------------------------------------------------- GET */

export const GET: APIRoute = async ({ url }) => {
  const yol = url.searchParams.get('yol');
  if (!yolGecerliMi(yol)) return json({ hata: 'Geçersiz yol.' }, 400);
  if (!kvKurulu()) return json({ yorumlar: [], kapali: true });

  try {
    const kayitlar = await kv<Record<string, string> | null>(['HGETALL', ANAHTAR.onayli(yol)]);
    // Upstash HGETALL'ı düz dizi döndürür: [alan, deger, alan, deger…]
    const dizi = Array.isArray(kayitlar) ? kayitlar : [];
    const yorumlar: any[] = [];
    for (let i = 1; i < dizi.length; i += 2) {
      try {
        const y = JSON.parse(dizi[i] as string);
        yorumlar.push({ id: y.id, ad: y.ad, metin: y.metin, tarih: y.tarih, yanit: y.yanit ?? null });
      } catch {
        /* bozuk kayıt atlanır */
      }
    }
    yorumlar.sort((a, b) => String(a.tarih).localeCompare(String(b.tarih)));
    return json({ yorumlar });
  } catch (e) {
    return json({ hata: e instanceof Error ? e.message : 'Yorumlar okunamadı.' }, 502);
  }
};

/* ------------------------------------------------------------------- POST */

export const POST: APIRoute = async ({ request }) => {
  if (!kvKurulu()) {
    return json({ hata: 'Yorumlar şu anda kapalı: depo yapılandırılmamış.' }, 503);
  }

  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return json({ hata: 'Gövde okunamadı.' }, 400);
  }

  const { yol, ad, eposta, metin, tuzak, acilis } = govde as Record<string, any>;

  /* --- bot denetimleri ---------------------------------------------------- */
  // Gizli alan doldurulmuşsa gönderen bir bottur; başarılı gibi cevap veriyoruz
  // ki yeniden denemesin.
  if (tuzak) return json({ tamam: true, beklemede: true });

  const gecenMs = Date.now() - Number(acilis ?? 0);
  if (!Number.isFinite(gecenMs) || gecenMs < 3000) {
    return json({ hata: 'Form çok hızlı gönderildi. Birkaç saniye sonra tekrar deneyin.' }, 400);
  }
  if (gecenMs > 6 * 60 * 60 * 1000) {
    return json({ hata: 'Form çok uzun süre açık kaldı. Sayfayı yenileyip tekrar deneyin.' }, 400);
  }

  /* --- alan denetimleri --------------------------------------------------- */
  if (!yolGecerliMi(yol)) return json({ hata: 'Geçersiz yol.' }, 400);

  const temizAd = String(ad ?? '').trim();
  const temizMetin = String(metin ?? '').trim();
  const temizEposta = String(eposta ?? '').trim();

  if (temizAd.length < 2 || temizAd.length > 40) {
    return json({ hata: 'Ad 2 ile 40 karakter arasında olmalı.' }, 400);
  }
  if (temizMetin.length < 10 || temizMetin.length > 2000) {
    return json({ hata: 'Yorum 10 ile 2000 karakter arasında olmalı.' }, 400);
  }
  if (temizEposta && (temizEposta.length > 80 || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(temizEposta))) {
    return json({ hata: 'E-posta adresi geçersiz görünüyor.' }, 400);
  }

  const bagSayisi = (temizMetin.match(/https?:\/\//gi) ?? []).length;
  if (bagSayisi > 2) {
    return json({ hata: 'Yorumda ikiden fazla bağlantı olamaz.' }, 400);
  }

  /* --- hız sınırı ---------------------------------------------------------- */
  const ip =
    request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    request.headers.get('x-real-ip') ??
    'bilinmeyen';
  const tuz = import.meta.env.OTURUM_ANAHTARI ?? 'bilgince';

  try {
    const parmak = await parmakIzi(ip, tuz);
    const { asildi } = await hizSiniri(parmak, 3, 600);
    if (asildi) {
      return json({ hata: 'Kısa sürede çok fazla yorum gönderildi. On dakika sonra tekrar deneyin.' }, 429);
    }

    const id = String(await kv<number>(['INCR', ANAHTAR.sayac]));
    const kayit = {
      id,
      yol,
      ad: temizAd,
      eposta: temizEposta || null, // yalnızca panelde görünür, sitede asla
      metin: temizMetin,
      tarih: new Date().toISOString(),
      parmak,
    };

    await kv(['HSET', ANAHTAR.bekleyen, id, JSON.stringify(kayit)]);

    return json({
      tamam: true,
      beklemede: true,
      mesaj: 'Yorumunuz alındı. Onaylandıktan sonra yayımlanacak.',
    });
  } catch (e) {
    return json({ hata: e instanceof Error ? e.message : 'Yorum kaydedilemedi.' }, 502);
  }
};
