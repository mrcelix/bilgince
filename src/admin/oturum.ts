/**
 * Yönetim paneli oturumu — Google ile giriş.
 *
 * Akış: /api/admin/google-basla → Google → /api/admin/google-donus → çerez.
 * Çerez HMAC-SHA256 ile imzalanır; sunucu dışında üretilemez, değiştirilemez.
 * Yetki tek yerde: ADMIN_EPOSTALAR listesinde olmayan hiçbir hesap giremez.
 */

const CEREZ = 'bilgince_oturum';
const SURE_SANIYE = 12 * 60 * 60; // 12 saat

export type Oturum = { eposta: string; ad?: string; resim?: string; bitis: number };

/* --------------------------------------------------------------- yapılandırma */

export function yapilandirma(env: Record<string, any> = import.meta.env) {
  const epostalar = String(env.ADMIN_EPOSTALAR ?? 'mcelik@gmail.com')
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);

  return {
    istemciId: env.GOOGLE_ISTEMCI_ID as string | undefined,
    istemciSir: env.GOOGLE_ISTEMCI_SIR as string | undefined,
    oturumAnahtari: env.OTURUM_ANAHTARI as string | undefined,
    epostalar,
    githubJeton: env.GITHUB_JETON as string | undefined,
    githubDepo: (env.GITHUB_DEPO as string) ?? 'mrcelix/bilgince',
    githubDal: (env.GITHUB_DAL as string) ?? 'main',
  };
}

/** Google girişi kurulu mu? Değilse panel yalnızca yerel geliştirmede açılır. */
export function girisKurulu(env?: Record<string, any>) {
  const y = yapilandirma(env);
  return Boolean(y.istemciId && y.istemciSir && y.oturumAnahtari);
}

export function yetkiliMi(eposta: string, env?: Record<string, any>) {
  return yapilandirma(env).epostalar.includes(eposta.trim().toLowerCase());
}

/* -------------------------------------------------------------------- imza */

const metin = (s: string) => new TextEncoder().encode(s);

const b64url = (veri: ArrayBuffer | Uint8Array) => {
  const bayt = veri instanceof Uint8Array ? veri : new Uint8Array(veri);
  let ikili = '';
  for (const b of bayt) ikili += String.fromCharCode(b);
  return btoa(ikili).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};

const b64urlCoz = (s: string) => {
  const dolgulu = s.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - (s.length % 4)) % 4);
  return new TextDecoder().decode(Uint8Array.from(atob(dolgulu), (c) => c.charCodeAt(0)));
};

async function anahtar(sir: string) {
  return crypto.subtle.importKey('raw', metin(sir), { name: 'HMAC', hash: 'SHA-256' }, false, [
    'sign',
    'verify',
  ]);
}

async function imzala(govde: string, sir: string) {
  return b64url(await crypto.subtle.sign('HMAC', await anahtar(sir), metin(govde)));
}

/* ------------------------------------------------------------------ çerez */

export async function oturumCerezi(oturum: Oturum, sir: string) {
  const govde = b64url(metin(JSON.stringify(oturum)));
  const imza = await imzala(govde, sir);
  const parcalar = [
    `${CEREZ}=${govde}.${imza}`,
    'Path=/',
    'HttpOnly',
    'SameSite=Lax',
    `Max-Age=${SURE_SANIYE}`,
  ];
  if (!import.meta.env.DEV) parcalar.push('Secure');
  return parcalar.join('; ');
}

export function silmeCerezi() {
  return `${CEREZ}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0`;
}

/** Çerezi doğrular; geçersiz, süresi dolmuş ya da yetkisizse null döner. */
export async function oturumOku(
  istek: Request,
  env?: Record<string, any>
): Promise<Oturum | null> {
  const y = yapilandirma(env);
  if (!y.oturumAnahtari) return null;

  const ham = istek.headers.get('cookie') ?? '';
  const deger = ham
    .split(';')
    .map((p) => p.trim())
    .find((p) => p.startsWith(`${CEREZ}=`))
    ?.slice(CEREZ.length + 1);
  if (!deger) return null;

  const [govde, imza] = deger.split('.');
  if (!govde || !imza) return null;

  const beklenen = await imzala(govde, y.oturumAnahtari);
  // Sabit süreli karşılaştırma: uzunluk aynı, fark bit bit toplanıyor
  if (imza.length !== beklenen.length) return null;
  let fark = 0;
  for (let i = 0; i < imza.length; i++) fark |= imza.charCodeAt(i) ^ beklenen.charCodeAt(i);
  if (fark !== 0) return null;

  try {
    const oturum = JSON.parse(b64urlCoz(govde)) as Oturum;
    if (!oturum?.eposta || oturum.bitis < Date.now()) return null;
    if (!yetkiliMi(oturum.eposta, env)) return null;
    return oturum;
  } catch {
    return null;
  }
}

export function yeniOturum(eposta: string, ad?: string, resim?: string): Oturum {
  return { eposta, ad, resim, bitis: Date.now() + SURE_SANIYE * 1000 };
}

/* ------------------------------------------------------- Google uç noktaları */

export const GOOGLE_YETKI = 'https://accounts.google.com/o/oauth2/v2/auth';
export const GOOGLE_JETON = 'https://oauth2.googleapis.com/token';

export function donusAdresi(url: URL) {
  return `${url.origin}/api/admin/google-donus`;
}

/**
 * id_token'ın gövdesini okur. İmza doğrulaması yapılmıyor çünkü belirteç
 * Google'ın jeton uç noktasından TLS üzerinden, istemci sırrıyla doğrudan
 * alındı (OpenID Connect 3.1.3.7: bu durumda imza doğrulaması zorunlu değil).
 */
export function idBelirteciCoz(idToken: string): { email?: string; name?: string; picture?: string; email_verified?: boolean } {
  const govde = idToken.split('.')[1];
  if (!govde) return {};
  try {
    return JSON.parse(b64urlCoz(govde));
  } catch {
    return {};
  }
}
