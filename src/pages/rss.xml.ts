import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import { SITE } from '../site.js';
import type { APIContext } from 'astro';

export async function GET(context: APIContext) {
  const rehberler = (await getCollection('rehberler'))
    .filter((r) => !r.data.taslak)
    .sort((a, b) => +b.data.yayin - +a.data.yayin);

  const ipuclari = await getCollection('ipuclari');

  const ogeler = [
    ...rehberler.map((r) => ({
      title: r.data.baslik,
      description: r.data.ozet,
      pubDate: r.data.yayin,
      link: `/rehberler/${r.id}`,
      categories: ['rehber', r.data.konu, ...r.data.etiketler],
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
