import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import { SITE } from '../site.js';
import type { APIContext } from 'astro';

export async function GET(context: APIContext) {
  const rehberler = (await getCollection('rehberler'))
    .filter((r) => !r.data.taslak)
    .sort((a, b) => +b.data.yayin - +a.data.yayin);

  const ipuclari = await getCollection('ipuclari');
  const cozumler = await getCollection('cozumler');

  const ogeler = [
    ...rehberler.map((r) => ({
      title: r.data.baslik,
      description: r.data.ozet,
      pubDate: r.data.yayin,
      link: `/rehberler/${r.id}`,
      categories: ['rehber', r.data.konu, ...r.data.etiketler],
      author: SITE.author.email,
    })),
    // Hızlı çözümler beslemenin dışında kalıyordu; kendi adresleri ve tarihleri
    // olan tam sayfalar, rehberlerle aynı şekilde duyurulmalı.
    ...cozumler.map((c) => ({
      title: `Hızlı çözüm: ${c.data.baslik}`,
      description: c.data.ozet,
      pubDate: c.data.yayin,
      link: `/hizli-cozumler/${c.id}`,
      categories: ['hizli-cozum', c.data.konu, ...c.data.etiketler],
      author: SITE.author.email,
    })),
    ...ipuclari.map((i) => ({
      title: `İpucu: ${i.data.baslik}`,
      description: i.data.ozet,
      pubDate: i.data.yayin,
      link: '/ipuclari',
      categories: ['ipucu', i.data.konu],
      author: SITE.author.email,
    })),
  ].sort((a, b) => +b.pubDate - +a.pubDate);

  return rss({
    title: SITE.title,
    description: SITE.description,
    site: context.site ?? SITE.url,
    customData: '<language>tr-TR</language>',
    items: ogeler,
  });
}
