import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

/**
 * Saha çantasının içerik dizini.
 *
 * Çanta yalnızca kimlik listesi tutuyor (localStorage'da ve paylaşım
 * adresinde). Komutun kendisi burada: böylece kimlik listesi kısa kalıyor,
 * paylaşılan bağlantı herhangi bir sayfada açılabiliyor ve dışa aktarma
 * içeriği hangi sayfada olursanız olun elinizin altında oluyor.
 */
export const GET: APIRoute = async () => {
  const komutlar = await getCollection('komutlar');
  const cozumler = await getCollection('cozumler');

  const ogeler = [
    ...komutlar.map((k) => ({
      kimlik: `komut:${k.id}`,
      tur: 'komut',
      baslik: k.data.baslik,
      ozet: k.data.ozet,
      kod: k.data.kod.trim(),
      dikkat: k.data.dikkat ?? null,
      konu: k.data.konu,
      adres: `/komutlar#${k.id}`,
    })),
    // Hızlı çözümlerin "30 saniyelik çözüm" satırı
    ...cozumler
      .filter((c) => c.data.komut)
      .map((c) => ({
        kimlik: `cozum:${c.id}`,
        tur: 'cozum',
        baslik: c.data.baslik,
        ozet: c.data.ozet,
        kod: c.data.komut!.trim(),
        dikkat: null,
        konu: c.data.konu,
        adres: `/hizli-cozumler/${c.id}`,
      })),
    // İndirilebilir betikler: kodu yerine indirme satırı konuyor
    ...cozumler
      .filter((c) => c.data.dosya)
      .map((c) => ({
        kimlik: `betik:${c.id}`,
        tur: 'betik',
        baslik: c.data.dosyaAdi ?? c.data.baslik,
        ozet: c.data.dosyaAciklama ?? c.data.ozet,
        kod: null,
        dosya: c.data.dosya!,
        dikkat: null,
        konu: c.data.konu,
        adres: `/hizli-cozumler/${c.id}`,
      })),
  ];

  return new Response(JSON.stringify({ ogeler }), {
    headers: {
      'content-type': 'application/json; charset=utf-8',
      // Derlemeyle birlikte değişiyor; uzun önbellek doğru değil
      'cache-control': 'public, max-age=0, s-maxage=600, stale-while-revalidate=604800',
    },
  });
};
