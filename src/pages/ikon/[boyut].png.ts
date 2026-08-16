import type { APIRoute } from 'astro';
import satori from 'satori';
import sharp from 'sharp';
import fs from 'node:fs/promises';
import path from 'node:path';

/* --------------------------------------------------------------------------
   PNG ikonlar. Sitede yalnızca `favicon.svg` vardı; iOS ana ekrana eklemede
   SVG kabul etmiyor ve bulanık bir ekran görüntüsü koyuyordu, Android'in
   uygulama listesi de manifest ikonu istiyor.

   Çizim satori ile yapılıyor, `favicon.svg`'yi sharp'a vererek değil: o yol
   yazı tipini sistemden arıyor, Nunito kurulu olmadığında harf yedek bir
   yazı tipiyle ve kaymış olarak çıkıyordu. Satori yazı tipi dosyasını gömüyor,
   sonuç her makinede aynı.

   Küçük boyutlarda beyaz zemin üstündeki ince harf kayboluyor; bu yüzden ikon
   degrade dolgulu karo, harf beyaz. Maskelenebilir (maskable) ikon için de
   doğru biçim bu: köşeler kırpılsa da işaret ortada kalıyor.
   -------------------------------------------------------------------------- */

const BOYUTLAR = {
  '180': 180, // apple-touch-icon
  '192': 192, // manifest — Android ana ekran
  '512': 512, // manifest — açılış ekranı
  '32': 32, // favicon.png yedeği
} as const;

export function getStaticPaths() {
  return Object.keys(BOYUTLAR).map((boyut) => ({ params: { boyut } }));
}

const FONT_DIZIN = path.resolve('src/assets/fonts');

async function fontlar() {
  const oku = (dosya: string) => fs.readFile(path.join(FONT_DIZIN, dosya));
  return [
    { name: 'Nunito', data: await oku('nunito-latin-800-normal.woff'), weight: 800, style: 'normal' },
  ] as Parameters<typeof satori>[1]['fonts'];
}

/** favicon.svg ile aynı degrade; orada harfte, burada zeminde. */
const karo = (kenar: number) => ({
  type: 'div',
  props: {
    style: {
      width: kenar,
      height: kenar,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      // Maskelenebilir ikonun güvenli alanı: köşeleri kırpılabilir, harf ortada
      borderRadius: kenar * 0.22,
      backgroundImage: 'linear-gradient(135deg, #3A45E0 0%, #7B3FD4 45%, #E8901A 100%)',
      fontFamily: 'Nunito',
      color: '#FFFFFF',
    },
    children: {
      type: 'div',
      props: {
        style: {
          display: 'flex',
          fontSize: kenar * 0.68,
          fontWeight: 800,
          letterSpacing: `${-kenar * 0.03}px`,
          // Nunito'nun 'b' harfi optik olarak biraz yukarı oturuyor
          marginTop: -kenar * 0.06,
        },
        children: 'b',
      },
      key: null,
    },
  },
  key: null,
});

export const GET: APIRoute = async ({ params }) => {
  const kenar = BOYUTLAR[params.boyut as keyof typeof BOYUTLAR];
  const svg = await satori(karo(kenar) as never, {
    width: kenar,
    height: kenar,
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
