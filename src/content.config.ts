import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const rehberler = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/rehberler' }),
  schema: z.object({
    baslik: z.string(),
    ozet: z.string(),
    // <title> ve meta description için, boş bırakılırsa baslik/ozet kullanılır
    seoBaslik: z.string().optional(),
    konu: z.string(),
    etiketler: z.array(z.string()).default([]),
    yayin: z.coerce.date(),
    guncelleme: z.coerce.date().optional(),
    sure: z.number(),
    seri: z.string().optional(),
    seriSira: z.number().optional(),
    oneCikan: z.boolean().default(false),
    taslak: z.boolean().default(false),
  }),
});

const ipuclari = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/ipuclari' }),
  schema: z.object({
    baslik: z.string(),
    ozet: z.string(),
    konu: z.string(),
    yayin: z.coerce.date(),
    sure: z.number().default(2),
    gununIpucu: z.boolean().default(false),
    // 1 = en çok ilgi gören. /ipuclari sayfası buna göre sıralar.
    populerlik: z.number().default(999),
    etiketler: z.array(z.string()).default([]),
    // ana sayfadaki terminal kutusu için
    komut: z.string().optional(),
    cikti: z.string().optional(),
    terminalBaslik: z.string().default('PowerShell 7'),
  }),
});

const projeler = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/projeler' }),
  schema: z.object({
    baslik: z.string(),
    ozet: z.string(),
    rol: z.string(),
    sureMetni: z.string(),
    yil: z.string(),
    kapsam: z.string(),
    sorun: z.string(),
    yaklasim: z.string(),
    sonuc: z.string(),
    teknolojiler: z.array(z.string()).default([]),
    metrikler: z.array(z.object({ deger: z.string(), etiket: z.string() })).default([]),
    asamalar: z
      .array(z.object({ baslik: z.string(), aciklama: z.string(), zaman: z.string() }))
      .default([]),
    ilgiliRehberler: z.array(z.string()).default([]),
    sira: z.number().default(0),
  }),
});

const komutlar = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/komutlar' }),
  schema: z.object({
    baslik: z.string(),
    ozet: z.string(),
    konu: z.string(),
    etiketler: z.array(z.string()).default([]),
    kod: z.string(),
    dikkat: z.string().optional(),
    ilgiliRehber: z.string().optional(),
  }),
});

export const collections = { rehberler, ipuclari, projeler, komutlar };
