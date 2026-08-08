import type { APIRoute } from 'astro';
import { dizinListele, dosyaOku, dosyaSil, dosyaYaz, yerelMi } from '../../../admin/depo';
import { frontmatterAyir } from '../../../admin/icerik';

export const prerender = false;

/**
 * Panelin dosya ucu. Yol denetimi tek kapıdan geçiyor: yalnızca içerik,
 * veri ve indirilebilir betik dizinleri yazılabilir. Bu liste olmadan panel,
 * depoya rastgele dosya yazabilen bir arka kapıya dönüşürdü.
 */
const IZINLI = ['src/content/', 'src/data/', 'public/araclar/'];

function yolGuvenliMi(yol: string) {
  if (!yol || yol.includes('..') || yol.includes('\\') || yol.startsWith('/')) return false;
  if (!IZINLI.some((on) => yol.startsWith(on))) return false;
  return /^[\w./-]+$/.test(yol);
}

const json = (govde: unknown, durum = 200) =>
  new Response(JSON.stringify(govde), {
    status: durum,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

/* -------------------------------------------------------------------- GET */

export const GET: APIRoute = async ({ url }) => {
  const dizin = url.searchParams.get('dizin');
  const yol = url.searchParams.get('yol');

  try {
    if (dizin) {
      if (!yolGuvenliMi(dizin + '/x')) return json({ hata: 'İzinsiz dizin.' }, 403);
      const adlar = await dizinListele(dizin);
      // Liste ekranında başlık gösterebilmek için her dosyanın frontmatter'ından
      // yalnızca başlık okunuyor; tam içerik açılınca geliyor.
      const kayitlar = await Promise.all(
        adlar.map(async (ad) => {
          try {
            const { icerik } = await dosyaOku(`${dizin}/${ad}`);
            const { yaml } = frontmatterAyir(icerik);
            const baslik = yaml.match(/^baslik:[ \t]*(.*)$/m)?.[1]?.replace(/^["']|["']$/g, '') ?? ad;
            const taslak = /^taslak:[ \t]*true/m.test(yaml);
            const yayin = yaml.match(/^yayin:[ \t]*(.*)$/m)?.[1]?.trim() ?? '';
            return { ad, baslik, taslak, yayin };
          } catch {
            return { ad, baslik: ad, taslak: false, yayin: '' };
          }
        })
      );
      return json({ dizin, kayitlar });
    }

    if (yol) {
      if (!yolGuvenliMi(yol)) return json({ hata: 'İzinsiz yol.' }, 403);
      const dosya = await dosyaOku(yol);
      return json({ yol, icerik: dosya.icerik });
    }

    return json({ hata: 'dizin ya da yol parametresi gerekli.' }, 400);
  } catch (e) {
    return json({ hata: e instanceof Error ? e.message : 'Okunamadı.' }, 502);
  }
};

/* -------------------------------------------------------------------- PUT */

export const PUT: APIRoute = async ({ request, locals }) => {
  let govde: { yol?: string; icerik?: string; mesaj?: string };
  try {
    govde = await request.json();
  } catch {
    return json({ hata: 'Gövde okunamadı.' }, 400);
  }

  const { yol, icerik, mesaj } = govde;
  if (!yol || typeof icerik !== 'string') return json({ hata: 'yol ve icerik gerekli.' }, 400);
  if (!yolGuvenliMi(yol)) return json({ hata: 'İzinsiz yol.' }, 403);
  if (icerik.length > 512_000) return json({ hata: 'İçerik çok büyük (512 KB sınırı).' }, 413);

  try {
    const sonuc = await dosyaYaz(
      yol,
      icerik,
      mesaj || `İçerik güncellendi: ${yol}`,
      locals.oturum?.eposta ?? 'bilinmeyen'
    );
    return json({
      tamam: true,
      nerede: sonuc.nerede,
      commit: sonuc.commit,
      not:
        sonuc.nerede === 'yerel'
          ? 'Dosya çalışma kopyanıza yazıldı; commit ve push sizde.'
          : 'Depoya commit edildi; Vercel birkaç dakika içinde yeniden yayınlar.',
    });
  } catch (e) {
    return json({ hata: e instanceof Error ? e.message : 'Yazılamadı.' }, 502);
  }
};

/* ----------------------------------------------------------------- DELETE */

export const DELETE: APIRoute = async ({ url, locals }) => {
  const yol = url.searchParams.get('yol');
  if (!yol || !yolGuvenliMi(yol)) return json({ hata: 'İzinsiz yol.' }, 403);
  try {
    await dosyaSil(yol, `İçerik silindi: ${yol}`, locals.oturum?.eposta ?? 'bilinmeyen');
    return json({ tamam: true, nerede: yerelMi() ? 'yerel' : 'github' });
  } catch (e) {
    return json({ hata: e instanceof Error ? e.message : 'Silinemedi.' }, 502);
  }
};
