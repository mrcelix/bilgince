import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import satori from 'satori';
import sharp from 'sharp';
import fs from 'node:fs/promises';
import path from 'node:path';
import { SITE, KONULAR } from '../../site.js';

/* --------------------------------------------------------------------------
   1200×630 paylaşım kartı. Yazı tipi TTF/WOFF olmak zorunda (satori woff2
   okuyamaz), o yüzden statik Nunito woff dosyalarını gömüyoruz. Türkçe
   karakterler latin-ext alt kümesinde; ayrı aile adıyla yedek olarak veriliyor.
   -------------------------------------------------------------------------- */

const FONT_DIZIN = path.resolve('src/assets/fonts');

async function fontlar() {
  const oku = (dosya: string) => fs.readFile(path.join(FONT_DIZIN, dosya));
  return [
    { name: 'Nunito', data: await oku('nunito-latin-400-normal.woff'), weight: 400, style: 'normal' },
    { name: 'Nunito', data: await oku('nunito-latin-800-normal.woff'), weight: 800, style: 'normal' },
    { name: 'NunitoX', data: await oku('nunito-latin-ext-400-normal.woff'), weight: 400, style: 'normal' },
    { name: 'NunitoX', data: await oku('nunito-latin-ext-800-normal.woff'), weight: 800, style: 'normal' },
  ] as Parameters<typeof satori>[1]['fonts'];
}

type Ogeler = Record<string, unknown> | Record<string, unknown>[] | string | undefined;
const e = (type: string, style: Record<string, unknown>, children?: Ogeler) => ({
  type,
  props: { style, children },
  key: null,
});

function kart({ ust, baslik, alt }: { ust: string; baslik: string; alt: string }) {
  return e(
    'div',
    {
      width: 1200,
      height: 630,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      padding: '66px 72px',
      backgroundColor: '#16203A',
      backgroundImage: 'linear-gradient(145deg, #16203A 0%, #1E2B4D 58%, #2B3A6B 100%)',
      fontFamily: 'Nunito, NunitoX',
      color: '#FFFFFF',
    },
    [
      e('div', { display: 'flex', flexDirection: 'column' }, [
        e('div', { width: 78, height: 8, borderRadius: 999, backgroundColor: '#EFA013' }),
        e(
          'div',
          {
            marginTop: 26,
            fontSize: 24,
            fontWeight: 800,
            letterSpacing: '0.12em',
            textTransform: 'uppercase',
            color: '#AEB7FF',
          },
          ust
        ),
        e(
          'div',
          {
            marginTop: 18,
            fontSize: baslik.length > 58 ? 60 : 70,
            fontWeight: 800,
            letterSpacing: '-0.035em',
            lineHeight: 1.06,
            display: 'flex',
          },
          baslik
        ),
      ]),
      e('div', { display: 'flex', alignItems: 'center' }, [
        e(
          'div',
          {
            width: 56,
            height: 56,
            borderRadius: 16,
            backgroundColor: '#3A45E0',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 22,
            fontWeight: 800,
            letterSpacing: '-0.03em',
          },
          'bc'
        ),
        e('div', { marginLeft: 20, fontSize: 26, fontWeight: 800 }, SITE.author.name),
        e('div', { marginLeft: 16, fontSize: 26, fontWeight: 400, color: '#9FA9BF' }, alt),
      ]),
    ]
  );
}

export async function getStaticPaths() {
  const rehberler = (await getCollection('rehberler')).filter((r) => !r.data.taslak);
  const projeler = await getCollection('projeler');
  const konuAdi = (slug: string) => KONULAR.find((k) => k.slug === slug)?.ad ?? slug;

  return [
    {
      params: { slug: 'site' },
      props: {
        ust: 'BT rehberleri ve saha ipuçları',
        baslik: 'Üretim ortamında denenmiş teknik rehberler',
        alt: `· ${SITE.url.replace('https://', '')}`,
      },
    },
    ...rehberler.map((r) => ({
      params: { slug: r.id },
      props: {
        ust: `Rehber · ${konuAdi(r.data.konu)}`,
        baslik: r.data.baslik,
        alt: `· ${SITE.url.replace('https://', '')} · ${r.data.sure} dk`,
      },
    })),
    ...projeler.map((p) => ({
      params: { slug: `proje-${p.id}` },
      props: {
        ust: `Proje · ${p.data.yil}`,
        baslik: p.data.baslik,
        alt: `· ${SITE.url.replace('https://', '')}`,
      },
    })),
  ];
}

export const GET: APIRoute = async ({ props }) => {
  const svg = await satori(kart(props as { ust: string; baslik: string; alt: string }) as never, {
    width: 1200,
    height: 630,
    fonts: await fontlar(),
  });

  const png = await sharp(Buffer.from(svg)).png().toBuffer();

  return new Response(new Uint8Array(png), {
    headers: {
      'Content-Type': 'image/png',
      'Cache-Control': 'public, max-age=31536000, immutable',
    },
  });
};
