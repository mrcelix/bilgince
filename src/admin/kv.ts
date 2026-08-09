/**
 * Yorumlar için anahtar-değer deposu (Upstash Redis / Vercel KV).
 *
 * SDK eklemiyoruz: Upstash'in REST arayüzü tek bir fetch ile çalışıyor, bu da
 * bağımlılık listesini ve derleme boyutunu olduğu yerde tutuyor. Vercel'in KV
 * ürünü de aynı arayüzü sunduğu için iki değişken adlandırması da destekleniyor.
 */

type Komut = (string | number)[];

export function kvYapilandirma(env: Record<string, any> = import.meta.env) {
  return {
    adres: (env.KV_REST_API_URL ?? env.UPSTASH_REDIS_REST_URL) as string | undefined,
    jeton: (env.KV_REST_API_TOKEN ?? env.UPSTASH_REDIS_REST_TOKEN) as string | undefined,
  };
}

export function kvKurulu(env?: Record<string, any>) {
  const y = kvYapilandirma(env);
  return Boolean(y.adres && y.jeton);
}

async function istek(govde: unknown, env?: Record<string, any>) {
  const y = kvYapilandirma(env);
  if (!y.adres || !y.jeton) {
    throw new Error('Yorum deposu yapılandırılmamış (KV_REST_API_URL / KV_REST_API_TOKEN eksik).');
  }

  const cevap = await fetch(y.adres, {
    method: 'POST',
    headers: { authorization: `Bearer ${y.jeton}`, 'content-type': 'application/json' },
    body: JSON.stringify(govde),
    signal: AbortSignal.timeout(8000),
  });

  if (!cevap.ok) {
    const metin = await cevap.text();
    throw new Error(`Yorum deposu ${cevap.status} döndürdü: ${metin.slice(0, 160)}`);
  }
  return cevap.json();
}

/** Tek komut çalıştırır ve sonucu döndürür. */
export async function kv<T = any>(komut: Komut, env?: Record<string, any>): Promise<T> {
  const sonuc = await istek(komut, env);
  if (sonuc?.error) throw new Error(`Yorum deposu hatası: ${sonuc.error}`);
  return sonuc?.result as T;
}

/** Birden çok komutu tek istekte çalıştırır (boru hattı). */
export async function kvBoru<T = any[]>(komutlar: Komut[], env?: Record<string, any>): Promise<T> {
  const y = kvYapilandirma(env);
  if (!y.adres || !y.jeton) throw new Error('Yorum deposu yapılandırılmamış.');

  const cevap = await fetch(`${y.adres.replace(/\/$/, '')}/pipeline`, {
    method: 'POST',
    headers: { authorization: `Bearer ${y.jeton}`, 'content-type': 'application/json' },
    body: JSON.stringify(komutlar),
    signal: AbortSignal.timeout(8000),
  });
  if (!cevap.ok) throw new Error(`Yorum deposu ${cevap.status} döndürdü.`);
  const govde = await cevap.json();
  return govde.map((s: any) => s.result) as T;
}

/* ---------------------------------------------------------------- anahtarlar */

/** "/rehberler/win-bitlocker" → "rehberler:win-bitlocker" */
export function yolAnahtari(yol: string) {
  return yol
    .replace(/^\/+|\/+$/g, '')
    .replace(/[^a-zA-Z0-9/_-]/g, '')
    .replace(/\//g, ':')
    .slice(0, 120) || 'kok';
}

export const ANAHTAR = {
  bekleyen: 'yorum:bekleyen',
  onayli: (yol: string) => `yorum:onayli:${yolAnahtari(yol)}`,
  yollar: 'yorum:yollar',
  sayac: 'yorum:sayac',
  hiz: (parmak: string) => `yorum:hiz:${parmak}`,
};

/** Kaba kuvvet ve spam için basit hız sınırı: pencere başına en fazla N istek. */
export async function hizSiniri(parmak: string, enCok = 3, saniye = 600, env?: Record<string, any>) {
  const anahtar = ANAHTAR.hiz(parmak);
  const [adet] = await kvBoru<[number, unknown]>(
    [
      ['INCR', anahtar],
      ['EXPIRE', anahtar, saniye, 'NX'],
    ],
    env
  );
  return { asildi: Number(adet) > enCok, adet: Number(adet) };
}

/** IP'yi olduğu gibi saklamıyoruz; tuzlanmış özetin ilk 16 hanesi yeterli. */
export async function parmakIzi(ip: string, tuz: string) {
  const veri = new TextEncoder().encode(`${ip}|${tuz}`);
  const ozet = await crypto.subtle.digest('SHA-256', veri);
  return [...new Uint8Array(ozet)]
    .slice(0, 8)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}
