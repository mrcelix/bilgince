import type { APIRoute } from 'astro';
import { GOOGLE_YETKI, donusAdresi, girisKurulu, yapilandirma } from '../../../admin/oturum';

export const prerender = false;

/**
 * Google'a yönlendirir. CSRF için rastgele bir `state` üretilip hem adrese hem
 * kısa ömürlü bir çereze yazılır; dönüşte ikisi karşılaştırılır.
 */
export const GET: APIRoute = ({ url }) => {
  if (!girisKurulu()) {
    return new Response(
      'Google girişi yapılandırılmamış. GOOGLE_ISTEMCI_ID, GOOGLE_ISTEMCI_SIR ve OTURUM_ANAHTARI gerekir.',
      { status: 503, headers: { 'content-type': 'text/plain; charset=utf-8' } }
    );
  }

  const y = yapilandirma();
  const durum = crypto.randomUUID();

  const hedef = new URL(GOOGLE_YETKI);
  hedef.searchParams.set('client_id', y.istemciId!);
  hedef.searchParams.set('redirect_uri', donusAdresi(url));
  hedef.searchParams.set('response_type', 'code');
  hedef.searchParams.set('scope', 'openid email profile');
  hedef.searchParams.set('state', durum);
  // Hesap seçimi her seferinde sorulsun: birden çok Google hesabı olanlarda
  // sessizce yanlış hesapla giriş denemesi kafa karıştırıyor.
  hedef.searchParams.set('prompt', 'select_account');

  const cerez = [
    `bilgince_durum=${durum}`,
    'Path=/api/admin',
    'HttpOnly',
    'SameSite=Lax',
    'Max-Age=600',
    import.meta.env.DEV ? '' : 'Secure',
  ]
    .filter(Boolean)
    .join('; ');

  return new Response(null, {
    status: 302,
    headers: { location: hedef.toString(), 'set-cookie': cerez },
  });
};
