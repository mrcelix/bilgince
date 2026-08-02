import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const rehberler = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/rehberler' }),
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
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/ipuclari' }),
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
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/projeler' }),
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
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/komutlar' }),
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

// Hızlı Çözümler: belirtiden başlayıp indirilebilir bir araçla biten kayıtlar.
// Diğer koleksiyonlardaki ilgili içeriği de bir araya getirir.
const cozumler = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/cozumler' }),
  schema: z.object({
    baslik: z.string(),
    ozet: z.string(),
    konu: z.string(),
    etiketler: z.array(z.string()).default([]),
    // kullanıcının gördüğü belirtiler — sayfada arama bunlara da bakar
    belirtiler: z.array(z.string()).default([]),
    yayin: z.coerce.date(),
    sure: z.number().default(5),
    // indirilebilir araç (public/ altındaki yol)
    dosya: z.string().optional(),
    dosyaAdi: z.string().optional(),
    dosyaAciklama: z.string().optional(),
    // tek satırlık hızlı çözüm
    komut: z.string().optional(),
    platform: z.enum(['windows', 'macos', 'linux', 'genel']).default('windows'),
    ilgiliRehberler: z.array(z.string()).default([]),
    sira: z.number().default(50),
  }),
});

export const collections = { rehberler, ipuclari, projeler, komutlar, cozumler };
