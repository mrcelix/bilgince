import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import satori from 'satori';
import sharp from 'sharp';
import fs from 'node:fs/promises';
import path from 'node:path';
import { SITE, KONULAR, slugla } from '../../site.js';

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
            color: '#AEB7FF',
          },
          // satori'nin textTransform'u Türkçe'yi bilmez: "Seri" → "SERI" olurdu.
          // Büyütmeyi burada Türkçe kurallarıyla yapıyoruz ("SERİ").
          ust.toLocaleUpperCase('tr')
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
      // Simge yok: renkli kelime logo. Satori background-clip:text desteklemediği
      // için degrade yerine iki parçalı renklendirme kullanılıyor.
      e('div', { display: 'flex', alignItems: 'center' }, [
        e('div', { display: 'flex', fontSize: 32, fontWeight: 800, letterSpacing: '-0.04em' }, [
          e('div', { color: '#9FA6FF' }, 'bilgi'),
          e('div', { color: '#F0A93A' }, 'nce'),
        ]),
        e('div', { marginLeft: 26, fontSize: 26, fontWeight: 800 }, SITE.author.name),
        e('div', { marginLeft: 16, fontSize: 26, fontWeight: 400, color: '#9FA9BF' }, alt),
      ]),
    ]
  );
}

export async function getStaticPaths() {
  const rehberler = (await getCollection('rehberler')).filter((r) => !r.data.taslak);
  const projeler = await getCollection('projeler');
  const komutlar = await getCollection('komutlar');
  const konuAdi = (slug: string) => KONULAR.find((k) => k.slug === slug)?.ad ?? slug;
  const seriler = [...new Set(rehberler.map((r) => r.data.seri).filter(Boolean))] as string[];

  return [
    {
      params: { slug: 'site' },
      props: {
        ust: 'BT rehberleri ve saha ipuçları',
        baslik: 'Üretim ortamında denenmiş teknik rehberler',
        alt: '',
      },
    },
    ...rehberler.map((r) => ({
      params: { slug: r.id },
      props: {
        ust: `Rehber · ${konuAdi(r.data.konu)}`,
        baslik: r.data.baslik,
        alt: `· ${r.data.sure} dk okuma`,
      },
    })),
    ...projeler.map((p) => ({
      params: { slug: `proje-${p.id}` },
      props: { ust: `Proje · ${p.data.yil}`, baslik: p.data.baslik, alt: `· ${p.data.kapsam}` },
    })),
    ...KONULAR.map((k) => ({
      params: { slug: `konu-${k.slug}` },
      props: {
        ust: `Konu · ${k.grup}`,
        baslik: k.ad,
        alt: `· ${rehberler.filter((r) => r.data.konu === k.slug).length} rehber`,
      },
    })),
    ...seriler.map((s) => ({
      params: { slug: `seri-${slugla(s)}` },
      props: {
        ust: 'Seri',
        baslik: s,
        alt: `· ${rehberler.filter((r) => r.data.seri === s).length} bölüm`,
      },
    })),
    {
      params: { slug: 'sayfa-rehberler' },
      props: { ust: 'Arşiv', baslik: 'Tüm rehberler', alt: `· ${rehberler.length} yazı` },
    },
    {
      params: { slug: 'sayfa-komutlar' },
      props: { ust: 'Araçlar', baslik: 'Komut kütüphanesi', alt: `· ${komutlar.length} komut` },
    },
    {
      params: { slug: 'sayfa-portfolyo' },
      props: { ust: 'Portfolyo', baslik: 'Ölçülebilir sonuçla kapanan projeler', alt: '' },
    },
    {
      params: { slug: 'sayfa-hakkimda' },
      props: { ust: 'Hakkımda', baslik: 'Sunucu odasında öğrendiklerimi saklamıyorum', alt: '' },
    },
    {
      params: { slug: 'sayfa-ozgecmis' },
      props: {
        ust: `Özgeçmiş · ${SITE.author.jobTitle}`,
        baslik: SITE.author.name,
        alt: '· 12 yıl saha',
      },
    },
    {
      params: { slug: 'sayfa-ipuclari' },
      props: { ust: 'İpuçları', baslik: 'Tek ekranda biten teknik notlar', alt: '' },
    },
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
