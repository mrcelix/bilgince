// Arama indeksini doğru dizinde üretir ve dağıtım çıktısına taşır.
//
// İki tuzak var:
//  1. Adaptör kullanıldığında statik dosyalar dist/ değil dist/client/ altına
//     çıkıyor; pagefind'i dist üzerinde çalıştırmak indeksi yanlış yere yazar.
//  2. Vercel `.vercel/output/static` dizinini sunuyor ve adaptör bu dizini
//     pagefind çalışmadan önce dolduruyor; indeks elle kopyalanmalı.
import { existsSync, rmSync, cpSync, readdirSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';

const statikDizin = existsSync('dist/client') ? 'dist/client' : 'dist';

if (!existsSync(statikDizin)) {
  console.error(`Derleme çıktısı bulunamadı: ${statikDizin}`);
  process.exit(1);
}

console.log(`Arama indeksi üretiliyor: ${statikDizin}`);
execFileSync('npx', ['pagefind', '--site', statikDizin], {
  stdio: 'inherit',
  shell: process.platform === 'win32',
});

const kaynak = path.join(statikDizin, 'pagefind');
const hedef = '.vercel/output/static/pagefind';

if (existsSync(kaynak) && existsSync('.vercel/output/static')) {
  rmSync(hedef, { recursive: true, force: true });
  cpSync(kaynak, hedef, { recursive: true });
  console.log(`Indeks Vercel çıktısına kopyalandı (${readdirSync(hedef).length} öğe).`);
}
