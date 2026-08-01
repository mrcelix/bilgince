import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import { SITE } from '../site.js';
import type { APIContext } from 'astro';

export async function GET(context: APIContext) {
  const rehberler = (await getCollection('rehberler'))
    .filter((r) => !r.data.taslak)
    .sort((a, b) => +b.data.yayin - +a.data.yayin);

  return rss({
    title: SITE.title,
    description: SITE.description,
    site: context.site ?? SITE.url,
    customData: '<language>tr-TR</language>',
    items: rehberler.map((r) => ({
      title: r.data.baslik,
      description: r.data.ozet,
      pubDate: r.data.yayin,
      link: `/rehberler/${r.id}`,
      categories: [r.data.konu, ...r.data.etiketler],
      author: SITE.author.email,
    })),
  });
}
