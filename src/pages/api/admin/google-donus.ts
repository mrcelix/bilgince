import type { APIRoute } from 'astro';
import {
  GOOGLE_JETON,
  donusAdresi,
  girisKurulu,
  idBelirteciCoz,
  oturumCerezi,
  yapilandirma,
  yeniOturum,
  yetkiliMi,
} from '../../../admin/oturum';

export const prerender = false;

const hataSayfasi = (mesaj: string, durum = 400) =>
  new Response(
    `<!doctype html><meta charset="utf-8"><title>Giriş başarısız</title>
     <div style="font:16px/1.6 system-ui;max-width:34rem;margin:12vh auto;padding:0 1rem">
       <h1 style="font-size:20px">Giriş yapılamadı</h1>
       <p style="color:#6b7488">${mesaj}</p>
       <p><a href="/admin/giris">Giriş sayfasına dön</a></p>
     </div>`,
    { status: durum, headers: { 'content-type': 'text/html; charset=utf-8' } }
  );

export const GET: APIRoute = async ({ url, request }) => {
  if (!girisKurulu()) return hataSayfasi('Google girişi bu kurulumda yapılandırılmamış.', 503);

  const hata = url.searchParams.get('error');
  if (hata) return hataSayfasi(`Google isteği reddetti: ${hata}`);

  const kod = url.searchParams.get('code');
  const durum = url.searchParams.get('state');
  if (!kod || !durum) return hataSayfasi('Eksik parametre.');

  // CSRF: adresteki state ile çerezdeki aynı olmalı
  const cerezDurum = (request.headers.get('cookie') ?? '')
    .split(';')
    .map((p) => p.trim())
    .find((p) => p.startsWith('bilgince_durum='))
    ?.slice('bilgince_durum='.length);
  if (!cerezDurum || cerezDurum !== durum) {
    return hataSayfasi('Oturum doğrulaması başarısız (state uyuşmadı). Girişi baştan deneyin.');
  }

  const y = yapilandirma();

  let idToken: string | undefined;
  try {
    const cevap = await fetch(GOOGLE_JETON, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code: kod,
        client_id: y.istemciId!,
        client_secret: y.istemciSir!,
        redirect_uri: donusAdresi(url),
        grant_type: 'authorization_code',
      }),
    });
    const govde = await cevap.json();
    if (!cevap.ok) {
      return hataSayfasi(`Google jeton vermedi: ${govde.error_description ?? govde.error ?? cevap.status}`);
    }
    idToken = govde.id_token;
  } catch {
    return hataSayfasi('Google ile bağlantı kurulamadı.', 502);
  }

  if (!idToken) return hataSayfasi('Google kimlik belirteci döndürmedi.');

  const kimlik = idBelirteciCoz(idToken);
  const eposta = kimlik.email?.toLowerCase();

  if (!eposta) return hataSayfasi('Google hesabında e-posta bulunamadı.');
  if (kimlik.email_verified === false) return hataSayfasi('Bu Google hesabının e-postası doğrulanmamış.');
  if (!yetkiliMi(eposta)) {
    return hataSayfasi(
      `<b>${eposta}</b> bu panele yetkili değil. Yetkili hesaplar ADMIN_EPOSTALAR değişkeninde tanımlı.`,
      403
    );
  }

  const cerez = await oturumCerezi(
    yeniOturum(eposta, kimlik.name, kimlik.picture),
    y.oturumAnahtari!
  );

  return new Response(null, {
    status: 302,
    headers: [
      ['location', '/admin'],
      ['set-cookie', cerez],
      ['set-cookie', 'bilgince_durum=; Path=/api/admin; HttpOnly; SameSite=Lax; Max-Age=0'],
    ] as any,
  });
};
