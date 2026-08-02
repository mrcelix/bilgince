// dist içindeki kırık iç bağlantıları listeler.
// Adaptör kullanıldığında statik dosyalar dist/client altına çıkıyor.
import fs from 'node:fs';
import path from 'node:path';

const kok = fs.existsSync('dist/client') ? 'dist/client' : 'dist';

const dosyalar = [];
(function tara(d) {
  for (const g of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, g.name);
    g.isDirectory() ? tara(p) : dosyalar.push(p);
  }
})(kok);

const html = dosyalar.filter((f) => f.endsWith('.html'));

const varMi = (u) => {
  const t = u.split('#')[0].split('?')[0];
  if (t === '') return true;
  const temiz = t.replace(/^\//, '').replace(/\/$/, '');
  return (
    fs.existsSync(path.join(kok, temiz)) ||
    fs.existsSync(path.join(kok, temiz, 'index.html')) ||
    fs.existsSync(path.join(kok, temiz + '.html'))
  );
};

// sunucu tarafında çalışan rotalar statik çıktıda bulunmaz
const sunucuRotalari = /^\/(keystatic|api)(\/|$)/;

const kirik = new Map();
for (const f of html) {
  const s = fs.readFileSync(f, 'utf8');
  for (const m of s.matchAll(/(?:href|src)="([^"]+)"/g)) {
    const u = m[1];
    if (!u.startsWith('/') || u.startsWith('//')) continue;
    if (sunucuRotalari.test(u)) continue;
    if (!varMi(u)) {
      kirik.set(u, (kirik.get(u) || new Set()).add(f.replace(/\\/g, '/')));
    }
  }
}

console.log('Kök dizin:', kok);
console.log('HTML sayfa:', html.length);
if (kirik.size === 0) {
  console.log('KIRIK BAGLANTI YOK');
} else {
  for (const [u, nerede] of kirik) {
    console.log('KIRIK', u, '→', [...nerede].slice(0, 3).join(', '));
  }
  process.exitCode = 1;
}
