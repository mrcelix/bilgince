/**
 * Panelin içerik tanımları ve frontmatter işleme.
 *
 * Frontmatter'ı tam bir YAML ayrıştırıcısıyla okuyup yeniden yazmıyoruz:
 * gidiş-dönüşte yorumlar, sıralama ve iç içe yapılar (metrikler, aşamalar)
 * bozulur. Bunun yerine hızlı alanlar YAML metnindeki ilgili satırı yerinde
 * değiştiriyor; dosyanın geri kalanına dokunulmuyor.
 */

export type Alan = {
  anahtar: string;
  etiket: string;
  /** `blok`: YAML blok değeri (kod: | …) — çok satırlı içerik için */
  tur: 'metin' | 'uzunMetin' | 'sayi' | 'tarih' | 'onay' | 'liste' | 'secim' | 'blok';
  ipucu?: string;
  secenekler?: string[];
};

export type Koleksiyon = {
  slug: string;
  ad: string;
  tekil: string;
  dizin: string;
  uzanti: string;
  adres?: (id: string) => string;
  aciklama: string;
  alanlar: Alan[];
  govdeVar: boolean;
};

const ORTAK_KONU: Alan = {
  anahtar: 'konu',
  etiket: 'Konu',
  tur: 'metin',
  ipucu: 'src/data/konu/ altındaki dosya adlarından biri (örn. powershell)',
};

export const KOLEKSIYONLAR: Koleksiyon[] = [
  {
    slug: 'rehberler',
    ad: 'Rehberler',
    tekil: 'rehber',
    dizin: 'src/content/rehberler',
    uzanti: '.mdx',
    adres: (id) => `/rehberler/${id}`,
    aciklama: 'Uzun rehberler. Adres dosya adından türer; yayımlandıktan sonra değiştirmeyin.',
    govdeVar: true,
    alanlar: [
      { anahtar: 'baslik', etiket: 'Başlık', tur: 'metin' },
      { anahtar: 'ozet', etiket: 'Özet', tur: 'uzunMetin', ipucu: 'Meta açıklama olarak da kullanılır — 155 karakteri geçmesin.' },
      { anahtar: 'seoBaslik', etiket: 'SEO başlığı', tur: 'metin', ipucu: 'İsteğe bağlı' },
      ORTAK_KONU,
      { anahtar: 'etiketler', etiket: 'Etiketler', tur: 'liste' },
      { anahtar: 'yayin', etiket: 'Yayın tarihi', tur: 'tarih' },
      { anahtar: 'guncelleme', etiket: 'Güncelleme tarihi', tur: 'tarih', ipucu: 'İsteğe bağlı' },
      { anahtar: 'sure', etiket: 'Okuma süresi (dk)', tur: 'sayi' },
      { anahtar: 'seri', etiket: 'Seri', tur: 'metin', ipucu: 'İsteğe bağlı — serideki diğer yazılarla birebir aynı yazılmalı' },
      { anahtar: 'seriSira', etiket: 'Seri sırası', tur: 'sayi', ipucu: 'Kaçıncı bölüm. Seri sayfasındaki sıralama buna göre.' },
      { anahtar: 'oneCikan', etiket: 'Ana sayfada öne çıkar', tur: 'onay' },
      { anahtar: 'taslak', etiket: 'Taslak (hiçbir yerde görünmez)', tur: 'onay' },
    ],
  },
  {
    slug: 'ipuclari',
    ad: 'Hızlı ipuçları',
    tekil: 'ipucu',
    dizin: 'src/content/ipuclari',
    uzanti: '.mdx',
    adres: (id) => `/ipuclari#${id}`,
    aciklama:
      'Tek ekranda biten notlar. Hepsi /ipuclari sayfasında listelenir; "Günün ipucu" işaretli olan ana sayfaya çıkar.',
    govdeVar: true,
    alanlar: [
      { anahtar: 'baslik', etiket: 'Başlık', tur: 'metin' },
      { anahtar: 'ozet', etiket: 'Özet', tur: 'uzunMetin' },
      ORTAK_KONU,
      { anahtar: 'etiketler', etiket: 'Etiketler', tur: 'liste' },
      { anahtar: 'yayin', etiket: 'Yayın tarihi', tur: 'tarih' },
      { anahtar: 'sure', etiket: 'Süre (dk)', tur: 'sayi' },
      {
        anahtar: 'gununIpucu',
        etiket: 'Günün ipucu (ana sayfada)',
        tur: 'onay',
        ipucu: 'Ana sayfadaki terminal kutusunu bu kayıt doldurur. Yalnızca bir ipucunda işaretli olmalı.',
      },
      {
        anahtar: 'populerlik',
        etiket: 'Popülerlik sırası',
        tur: 'sayi',
        ipucu: '1 = en çok ilgi gören. /ipuclari sayfası bu sayıya göre sıralar; boş bırakılırsa sona düşer.',
      },
      { anahtar: 'komut', etiket: 'Terminal komutu', tur: 'blok', ipucu: 'Ana sayfadaki terminal kutusunda görünür' },
      { anahtar: 'cikti', etiket: 'Terminal çıktısı', tur: 'blok', ipucu: 'Komutun ürettiği örnek çıktı' },
      { anahtar: 'terminalBaslik', etiket: 'Terminal başlığı', tur: 'metin', ipucu: 'Varsayılan: PowerShell 7' },
    ],
  },
  {
    slug: 'komutlar',
    ad: 'Komut kütüphanesi',
    tekil: 'komut',
    dizin: 'src/content/komutlar',
    uzanti: '.mdx',
    adres: (id) => `/komutlar#${id}`,
    aciklama: 'Tek satırlık komutlar. Gövde isteğe bağlı; asıl içerik "kod" alanında.',
    govdeVar: true,
    alanlar: [
      { anahtar: 'baslik', etiket: 'Başlık', tur: 'metin' },
      { anahtar: 'ozet', etiket: 'Özet', tur: 'uzunMetin' },
      ORTAK_KONU,
      { anahtar: 'etiketler', etiket: 'Etiketler', tur: 'liste' },
      { anahtar: 'kod', etiket: 'Komut', tur: 'blok', ipucu: 'Çok satırlı olabilir; YAML blok değeri olarak yazılır.' },
      { anahtar: 'dikkat', etiket: 'Dikkat notu', tur: 'uzunMetin', ipucu: 'Komutun nerede patlayabileceği' },
      {
        anahtar: 'ilgiliRehber',
        etiket: 'İlgili rehber',
        tur: 'metin',
        ipucu: 'Rehberin dosya adı (uzantısız) — komut kartındaki "Ayrıntılı rehberi oku" bağlantısı',
      },
    ],
  },
  {
    slug: 'cozumler',
    ad: 'Hızlı Çözümler',
    tekil: 'çözüm',
    dizin: 'src/content/cozumler',
    uzanti: '.mdx',
    adres: (id) => `/hizli-cozumler/${id}`,
    aciklama: 'Belirtiden çözüme giden kayıtlar. "dosya" alanı doldurulursa araç menüsünde de görünür.',
    govdeVar: true,
    alanlar: [
      { anahtar: 'baslik', etiket: 'Başlık', tur: 'metin' },
      { anahtar: 'ozet', etiket: 'Özet', tur: 'uzunMetin' },
      ORTAK_KONU,
      { anahtar: 'etiketler', etiket: 'Etiketler', tur: 'liste' },
      {
        anahtar: 'belirtiler',
        etiket: 'Belirtiler',
        tur: 'liste',
        ipucu: 'Kullanıcının gördüğü şeyler, virgülle. Sayfanın başındaki kutu ve belirti araması bunları kullanır.',
      },
      { anahtar: 'yayin', etiket: 'Yayın tarihi', tur: 'tarih' },
      { anahtar: 'sure', etiket: 'Süre (dk)', tur: 'sayi' },
      { anahtar: 'komut', etiket: '30 saniyelik çözüm', tur: 'blok', ipucu: 'Tek satırlık hızlı çözüm; sayfanın başında kutu olarak çıkar' },
      { anahtar: 'dosya', etiket: 'İndirilebilir betik yolu', tur: 'metin', ipucu: '/araclar/betik.ps1' },
      { anahtar: 'dosyaAdi', etiket: 'Betik dosya adı', tur: 'metin' },
      { anahtar: 'dosyaAciklama', etiket: 'Betik açıklaması', tur: 'uzunMetin', ipucu: 'İndirme kutusunda görünür' },
      { anahtar: 'platform', etiket: 'Platform', tur: 'secim', secenekler: ['windows', 'macos', 'linux', 'genel'] },
      {
        anahtar: 'ilgiliRehberler',
        etiket: 'İlgili rehberler',
        tur: 'liste',
        ipucu: 'Rehber dosya adları (uzantısız), virgülle — yan sütundaki "Konuyu derinleştir" kutusu',
      },
      { anahtar: 'sira', etiket: 'Sıra', tur: 'sayi' },
    ],
  },
  {
    slug: 'projeler',
    ad: 'Portfolyo',
    tekil: 'proje',
    dizin: 'src/content/projeler',
    uzanti: '.mdx',
    adres: (id) => `/portfolyo/${id}`,
    aciklama: 'Sorun → Yaklaşım → Sonuç. Metrikler ve aşamalar iç içe yapıdadır; ham YAML alanından düzenlenir.',
    govdeVar: true,
    alanlar: [
      { anahtar: 'baslik', etiket: 'Başlık', tur: 'metin' },
      { anahtar: 'ozet', etiket: 'Özet', tur: 'uzunMetin' },
      { anahtar: 'rol', etiket: 'Rol', tur: 'metin' },
      { anahtar: 'sureMetni', etiket: 'Süre', tur: 'metin' },
      { anahtar: 'yil', etiket: 'Yıl', tur: 'metin' },
      { anahtar: 'kapsam', etiket: 'Kapsam', tur: 'metin' },
      { anahtar: 'sorun', etiket: 'Sorun', tur: 'uzunMetin' },
      { anahtar: 'yaklasim', etiket: 'Yaklaşım', tur: 'uzunMetin' },
      { anahtar: 'sonuc', etiket: 'Sonuç', tur: 'uzunMetin' },
      { anahtar: 'teknolojiler', etiket: 'Teknolojiler', tur: 'liste' },
      {
        anahtar: 'ilgiliRehberler',
        etiket: 'İlgili rehberler',
        tur: 'liste',
        ipucu: 'Rehber dosya adları (uzantısız), virgülle',
      },
      { anahtar: 'sira', etiket: 'Sıra', tur: 'sayi' },
    ],
  },
];

export const koleksiyonBul = (slug: string) => KOLEKSIYONLAR.find((k) => k.slug === slug);

/* ------------------------------------------------------- frontmatter işleme */

export function frontmatterAyir(icerik: string): { yaml: string; govde: string } {
  const e = icerik.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!e) return { yaml: '', govde: icerik };
  return { yaml: e[1], govde: e[2] ?? '' };
}

export function frontmatterBirlestir(yaml: string, govde: string) {
  const temizYaml = yaml.replace(/\s+$/, '');
  const temizGovde = govde.replace(/^\s+/, '');
  return `---\n${temizYaml}\n---\n\n${temizGovde}${temizGovde.endsWith('\n') ? '' : '\n'}`;
}

/** Üst düzey bir anahtarın ham değerini okur (satır bazlı, tırnaklar korunur). */
export function alanOku(yaml: string, anahtar: string): string | null {
  const desen = new RegExp(`^${anahtar}:[ \\t]*(.*)$`, 'm');
  const e = yaml.match(desen);
  return e ? e[1] : null;
}

/** Anahtarı yerinde değiştirir; yoksa sona ekler. Boş değer anahtarı siler. */
export function alanYaz(yaml: string, anahtar: string, deger: string | null): string {
  const desen = new RegExp(`^${anahtar}:[ \\t]*.*$`, 'm');
  if (deger === null || deger === '') {
    return yaml.replace(new RegExp(`^${anahtar}:[ \\t]*.*\\r?\\n?`, 'm'), '');
  }
  const satir = `${anahtar}: ${deger}`;
  return desen.test(yaml) ? yaml.replace(desen, satir) : `${yaml.replace(/\s+$/, '')}\n${satir}`;
}

/* ------------------------------------------------------------ blok değerler
   `kod: |` gibi çok satırlı alanlar satır bazlı yazılamaz: başlık satırından
   sonra iki boşlukla girintili gövde gelir. Okuma ve yazma bu girintiyi
   koruyacak şekilde ayrı ele alınıyor. */

export function blokOku(yaml: string, anahtar: string): string | null {
  const satirlar = yaml.split('\n');
  const bas = satirlar.findIndex((s) => new RegExp(`^${anahtar}:\\s*[|>]`).test(s));
  if (bas === -1) return null;

  const govde: string[] = [];
  for (let i = bas + 1; i < satirlar.length; i++) {
    const s = satirlar[i];
    if (s.trim() === '') {
      govde.push('');
      continue;
    }
    if (/^ {2,}/.test(s)) govde.push(s.replace(/^ {2}/, ''));
    else break;
  }
  while (govde.length && govde[govde.length - 1] === '') govde.pop();
  return govde.join('\n');
}

export function blokYaz(yaml: string, anahtar: string, metin: string): string {
  const satirlar = yaml.split('\n');
  const yeni = [`${anahtar}: |`, ...metin.replace(/\s+$/, '').split('\n').map((s) => '  ' + s)];
  const bas = satirlar.findIndex((s) => new RegExp(`^${anahtar}:`).test(s));

  if (bas === -1) return [...satirlar.filter((s, i) => s.trim() !== '' || i < satirlar.length - 1), ...yeni].join('\n');

  let son = bas + 1;
  if (/^[^:]*:\s*[|>]/.test(satirlar[bas])) {
    while (son < satirlar.length && (satirlar[son].trim() === '' || /^ {2,}/.test(satirlar[son]))) son++;
  }
  return [...satirlar.slice(0, bas), ...yeni, ...satirlar.slice(son)].join('\n');
}

/** Panelin gösterdiği değeri YAML gösterimine çevirir. */
export function yamlDeger(alan: Alan, girdi: string): string | null {
  const temiz = girdi.trim();
  if (temiz === '' && alan.tur !== 'onay') return null;

  switch (alan.tur) {
    case 'onay':
      return temiz === 'true' ? 'true' : 'false';
    case 'sayi':
      return String(Number(temiz) || 0);
    case 'tarih':
      return temiz;
    case 'liste': {
      const ogeler = temiz
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean)
        .map((s) => `"${s.replace(/"/g, '\\"')}"`);
      return `[${ogeler.join(', ')}]`;
    }
    default:
      // Tırnak gerektiren durumlar: iki nokta, tırnak, baştaki özel karakterler
      return /^[-?:{}\[\]#&*!|>'"%@`]|: |#/.test(temiz) || temiz.includes('"')
        ? `"${temiz.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`
        : `"${temiz}"`;
  }
}

/** YAML gösteriminden panelin göstereceği değere. */
export function paneleDeger(alan: Alan, ham: string | null): string {
  if (ham === null) return alan.tur === 'onay' ? 'false' : '';
  const temiz = ham.trim();
  if (alan.tur === 'liste') {
    return temiz
      .replace(/^\[|\]$/g, '')
      .split(',')
      .map((s) => s.trim().replace(/^["']|["']$/g, ''))
      .filter(Boolean)
      .join(', ');
  }
  return temiz.replace(/^["']|["']$/g, '');
}

/** Dosya adından güvenli bir slug üretir. */
export function slugTemizle(metin: string) {
  const harita: Record<string, string> = {
    ç: 'c', Ç: 'c', ğ: 'g', Ğ: 'g', ı: 'i', I: 'i', İ: 'i',
    ö: 'o', Ö: 'o', ş: 's', Ş: 's', ü: 'u', Ü: 'u',
  };
  return metin
    .replace(/[çÇğĞıIİöÖşŞüÜ]/g, (h) => harita[h] ?? h)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
}
