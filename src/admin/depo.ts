/**
 * Panelin dosya katmanı.
 *
 * Yerelde doğrudan diske yazar — değişiklik anında görünür, commit'i siz
 * yaparsınız. Canlıda dosya sistemi salt okunur olduğu için GitHub Contents
 * API'sine yazar: her kayıt bir commit, her commit bir yeniden yayın. Geçmiş
 * git'te durur, geri almak `git revert` kadar kolaydır.
 */

import { yapilandirma } from './oturum';

export type Dosya = { yol: string; icerik: string; sha?: string };

const API = 'https://api.github.com';

/** Yereldeyken Node dosya sistemi; üretimde bu dal hiç çalışmaz. */
async function yerelFs() {
  const fs = await import('node:fs/promises');
  const path = await import('node:path');
  return { fs, path, kok: process.cwd() };
}

export function yerelMi() {
  return import.meta.env.DEV;
}

/* ------------------------------------------------------------------ okuma */

export async function dosyaOku(yol: string, env?: Record<string, any>): Promise<Dosya> {
  if (yerelMi()) {
    const { fs, path, kok } = await yerelFs();
    const icerik = await fs.readFile(path.join(kok, yol), 'utf8');
    return { yol, icerik };
  }

  const y = yapilandirma(env);
  const cevap = await fetch(
    `${API}/repos/${y.githubDepo}/contents/${encodeURI(yol)}?ref=${encodeURIComponent(y.githubDal)}`,
    { headers: baslikBilgisi(y.githubJeton) }
  );
  if (!cevap.ok) throw new Error(`GitHub dosyayı vermedi (${cevap.status}): ${yol}`);
  const govde = await cevap.json();
  const icerik = new TextDecoder().decode(
    Uint8Array.from(atob(String(govde.content).replace(/\n/g, '')), (c) => c.charCodeAt(0))
  );
  return { yol, icerik, sha: govde.sha };
}

/** Bir dizindeki dosyaların adlarını verir (alt dizinler hariç). */
export async function dizinListele(dizin: string, env?: Record<string, any>): Promise<string[]> {
  if (yerelMi()) {
    const { fs, path, kok } = await yerelFs();
    const girdiler = await fs.readdir(path.join(kok, dizin), { withFileTypes: true });
    return girdiler.filter((g) => g.isFile()).map((g) => g.name).sort();
  }

  const y = yapilandirma(env);
  const cevap = await fetch(
    `${API}/repos/${y.githubDepo}/contents/${encodeURI(dizin)}?ref=${encodeURIComponent(y.githubDal)}`,
    { headers: baslikBilgisi(y.githubJeton) }
  );
  if (!cevap.ok) throw new Error(`GitHub dizini vermedi (${cevap.status}): ${dizin}`);
  const govde = await cevap.json();
  return (Array.isArray(govde) ? govde : [])
    .filter((g: any) => g.type === 'file')
    .map((g: any) => g.name as string)
    .sort();
}

/* ------------------------------------------------------------------ yazma */

export async function dosyaYaz(
  yol: string,
  icerik: string,
  mesaj: string,
  yazan: string,
  env?: Record<string, any>
): Promise<{ nerede: 'yerel' | 'github'; commit?: string }> {
  if (yerelMi()) {
    const { fs, path, kok } = await yerelFs();
    const tam = path.join(kok, yol);
    await fs.mkdir(path.dirname(tam), { recursive: true });
    await fs.writeFile(tam, icerik, 'utf8');
    return { nerede: 'yerel' };
  }

  const y = yapilandirma(env);
  if (!y.githubJeton) throw new Error('GITHUB_JETON tanımlı değil: canlıda kayıt yapılamaz.');

  // Var olan dosyanın sha değeri gerekiyor; yoksa yeni dosya demektir
  let sha: string | undefined;
  try {
    sha = (await dosyaOku(yol, env)).sha;
  } catch {
    sha = undefined;
  }

  const cevap = await fetch(`${API}/repos/${y.githubDepo}/contents/${encodeURI(yol)}`, {
    method: 'PUT',
    headers: { ...baslikBilgisi(y.githubJeton), 'content-type': 'application/json' },
    body: JSON.stringify({
      message: `${mesaj}\n\nPanelden düzenledi: ${yazan}`,
      content: base64(icerik),
      branch: y.githubDal,
      ...(sha ? { sha } : {}),
    }),
  });

  if (!cevap.ok) {
    const hata = await cevap.text();
    throw new Error(`GitHub yazamadı (${cevap.status}): ${hata.slice(0, 200)}`);
  }
  const govde = await cevap.json();
  return { nerede: 'github', commit: govde.commit?.sha?.slice(0, 7) };
}

export async function dosyaSil(
  yol: string,
  mesaj: string,
  yazan: string,
  env?: Record<string, any>
) {
  if (yerelMi()) {
    const { fs, path, kok } = await yerelFs();
    await fs.unlink(path.join(kok, yol));
    return { nerede: 'yerel' as const };
  }

  const y = yapilandirma(env);
  const mevcut = await dosyaOku(yol, env);
  const cevap = await fetch(`${API}/repos/${y.githubDepo}/contents/${encodeURI(yol)}`, {
    method: 'DELETE',
    headers: { ...baslikBilgisi(y.githubJeton), 'content-type': 'application/json' },
    body: JSON.stringify({
      message: `${mesaj}\n\nPanelden sildi: ${yazan}`,
      sha: mevcut.sha,
      branch: y.githubDal,
    }),
  });
  if (!cevap.ok) throw new Error(`GitHub silemedi (${cevap.status})`);
  return { nerede: 'github' as const };
}

/* --------------------------------------------------------------- yardımcı */

function baslikBilgisi(jeton?: string) {
  const h: Record<string, string> = {
    accept: 'application/vnd.github+json',
    'user-agent': 'bilgince-admin',
    'x-github-api-version': '2022-11-28',
  };
  if (jeton) h.authorization = `Bearer ${jeton}`;
  return h;
}

function base64(metin: string) {
  const bayt = new TextEncoder().encode(metin);
  let ikili = '';
  for (const b of bayt) ikili += String.fromCharCode(b);
  return btoa(ikili);
}

/** Panelin canlıda yazabilir durumda olup olmadığını söyler. */
export function yazabilirMi(env?: Record<string, any>) {
  return yerelMi() || Boolean(yapilandirma(env).githubJeton);
}
