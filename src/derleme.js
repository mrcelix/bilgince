// Altlıktaki derleme damgası. Modül derleme sırasında bir kez çalışır; üretilen
// tüm sayfalar aynı numarayı ve saati taşır. Canlıdaki sayfanın hangi commit'ten
// çıktığını ve ne zaman derlendiğini buradan görürsünüz — "değişiklik yayına
// çıktı mı" sorusunun cevabı.
import { execFileSync } from 'node:child_process';

/** Git yoksa ya da depo okunamıyorsa boş döner; derleme buna takılmamalı. */
function git(...argumanlar) {
  try {
    // safe.directory: derleme kullanıcısı depo sahibinden farklı olabiliyor
    return execFileSync('git', ['-c', 'safe.directory=*', ...argumanlar], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return '';
  }
}

// Vercel ve GitHub Actions commit'i ortam değişkeninde verir; yerelde git'e sorulur.
const tamSurum = process.env.VERCEL_GIT_COMMIT_SHA || process.env.GITHUB_SHA || git('rev-parse', 'HEAD');
// Yerelde commit'lenmemiş değişiklikle derlendiyse numaranın sonuna "+" gelir:
// "a4067b3+" gördüğünüz sayfa depodaki hiçbir commit'e birebir denk değildir.
const kirli = !process.env.VERCEL_GIT_COMMIT_SHA && !process.env.GITHUB_SHA && git('status', '--porcelain') !== '';
const zaman = new Date();

export const DERLEME = {
  /** Kısa commit numarası; git de ortam değişkeni de yoksa "yerel" */
  surum: tamSurum ? tamSurum.slice(0, 7) + (kirli ? '+' : '') : 'yerel',
  tamSurum: tamSurum || '',
  zamanISO: zaman.toISOString(),
  // Sunucu UTC'de derliyor; okuyan da yazan da Türkiye saatini bekliyor
  zamanMetin: new Intl.DateTimeFormat('tr-TR', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZone: 'Europe/Istanbul',
  }).format(zaman),
};
