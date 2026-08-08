import { defineMiddleware } from 'astro:middleware';
import { oturumOku, girisKurulu, type Oturum } from './admin/oturum';

/**
 * /admin ve /api/admin altındaki her şey oturum ister. Tek istisna giriş
 * sayfası ve Google dönüş ucu — onlar zaten oturum kurmak için var.
 *
 * Yerel geliştirmede Google yapılandırılmamışsa panel sahte bir oturumla
 * açılır. Bu dal yalnızca `astro dev` sırasında derlenir; üretim çıktısında
 * import.meta.env.DEV sabit olarak false olduğu için hiç yer almaz.
 */
export const onRequest = defineMiddleware(async (baglam, sonraki) => {
  const yol = baglam.url.pathname;
  const korumali = yol.startsWith('/admin') || yol.startsWith('/api/admin');
  if (!korumali) return sonraki();

  const serbest = yol === '/admin/giris' || yol.startsWith('/api/admin/google-');
  if (serbest) return sonraki();

  const oturum = await oturumOku(baglam.request);

  if (!oturum) {
    if (import.meta.env.DEV && !girisKurulu()) {
      baglam.locals.oturum = {
        eposta: 'yerel@gelistirme',
        ad: 'Yerel geliştirme',
        bitis: Date.now() + 3600_000,
      } satisfies Oturum;
      return sonraki();
    }
    if (yol.startsWith('/api/')) {
      return new Response(JSON.stringify({ hata: 'Oturum yok ya da süresi doldu.' }), {
        status: 401,
        headers: { 'content-type': 'application/json; charset=utf-8' },
      });
    }
    return baglam.redirect('/admin/giris');
  }

  baglam.locals.oturum = oturum;
  return sonraki();
});
