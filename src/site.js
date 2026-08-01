// Sitenin tek doğruluk kaynağı. İsim, alan adı ve imza burada değişir.
export const SITE = {
  name: 'bilgince',
  url: 'https://bilgince.com',
  title: 'bilgince — BT rehberleri ve saha ipuçları',
  description:
    'Windows Server, Active Directory, PowerShell ve ağ üzerine üretim ortamında denenmiş rehberler. Her yazının sonunda doğrulama adımı var.',
  locale: 'tr_TR',
  lang: 'tr',
  author: {
    name: 'Mustafa Çelik',
    initials: 'MÇ',
    jobTitle: 'Kıdemli Sistem Yöneticisi',
    worksFor: 'Anadolu Lojistik A.Ş.',
    location: 'Ankara',
    email: 'merhaba@bilgince.com',
    linkedin: 'https://www.linkedin.com/in/mustafacelik',
    github: 'https://github.com/mrcelix',
    knowsAbout: [
      'Windows Server',
      'Active Directory',
      'PowerShell',
      'Hyper-V',
      'Microsoft Entra ID',
      'Ağ güvenliği',
    ],
  },
  newsletter: {
    subscribers: 4812,
    cadence: 'Haftada bir e-posta',
    // Bülten sağlayıcısının form uç noktası. Boş bırakılırsa form yerine
    // "henüz bağlanmadı" notu görünür — sessizce yutulan kayıt olmaz.
    // Buttondown:  https://buttondown.com/api/emails/embed-subscribe/<kullanici>
    // Kit (ConvertKit): https://app.kit.com/forms/<form-id>/subscriptions
    // Listmonk:    https://liste.alanadiniz.com/subscription/form
    endpoint: '',
    // Uç nokta e-posta alanını hangi adla bekliyor
    alanAdi: 'email',
  },
};

/**
 * Konu taksonomisi. Mega menüde GRUPLAR sırasına göre sütunlara bölünür,
 * /konu/<slug> adreslerine karşılık gelir.
 * `ikon` değerleri src/components/KonuIkon.astro içinde tanımlı.
 */
export const GRUPLAR = [
  { ad: 'Bulut', ozet: 'Üç sağlayıcı, operasyon gözüyle' },
  { ad: 'Altyapı', ozet: 'Sunucu, istemci, otomasyon' },
  { ad: 'Ağ & Güvenlik', ozet: 'Bağlantı ve kimlik' },
  { ad: 'Süreç & Süreklilik', ozet: 'İşin devam etmesini sağlayan taraf' },
];

export const KONULAR = [
  // --- Bulut ---
  { slug: 'azure', ad: 'Microsoft Azure', ozet: 'Kimlik, ağ, maliyet ve yönetişim', grup: 'Bulut', ikon: 'bulut' },
  { slug: 'aws', ad: 'AWS', ozet: 'IAM, VPC, maliyet ve dayanıklılık', grup: 'Bulut', ikon: 'bulut' },
  { slug: 'google-cloud', ad: 'Google Cloud', ozet: 'Proje hiyerarşisi, IAM, GKE', grup: 'Bulut', ikon: 'bulut' },

  // --- Altyapı ---
  { slug: 'windows-server', ad: 'Windows Server', ozet: 'Rol kurulumu, güncelleme, sertleştirme', grup: 'Altyapı', ikon: 'sunucu' },
  { slug: 'windows', ad: 'Windows İstemci', ozet: 'Masaüstü ipuçları ve sorun giderme', grup: 'Altyapı', ikon: 'pencere' },
  { slug: 'powershell', ad: 'PowerShell', ozet: 'Otomasyon, raporlama, zamanlanmış görev', grup: 'Altyapı', ikon: 'terminal' },
  { slug: 'sanallastirma', ad: 'Sanallaştırma', ozet: 'Hyper-V, depolama, checkpoint yönetimi', grup: 'Altyapı', ikon: 'kutu' },

  // --- Ağ & Güvenlik ---
  { slug: 'ag', ad: 'Ağ', ozet: 'Yönlendirme, VPN, güvenlik duvarı kuralları', grup: 'Ağ & Güvenlik', ikon: 'kure' },
  { slug: 'sd-wan', ad: 'SD-WAN', ozet: 'Şube bağlantısı, yol seçimi, SASE', grup: 'Ağ & Güvenlik', ikon: 'dugum' },
  { slug: 'guvenlik', ad: 'Güvenlik & Entra ID', ozet: 'MFA, koşullu erişim, kimlik göçü', grup: 'Ağ & Güvenlik', ikon: 'kalkan' },

  // --- Süreç & Süreklilik ---
  { slug: 'itsm', ad: 'ITSM', ozet: 'Olay, değişiklik, problem ve SLA yönetimi', grup: 'Süreç & Süreklilik', ikon: 'akis' },
  { slug: 'yedekleme', ad: 'Yedekleme & kurtarma', ozet: 'Doğrulama rutini, RPO/RTO, tatbikat', grup: 'Süreç & Süreklilik', ikon: 'geri' },
];

export const POPULER_ARAMALAR = [
  'hesap kilitleniyor',
  'robocopy /MIR',
  '4740 olayı',
  'SMB over QUIC',
  'GPO yedekleme',
];

// Arşiv sayfası başına yazı sayısı.
export const SAYFA_BASI = 12;

/**
 * Türkçe karakterleri koruyarak URL parçası üretir.
 * "Sıfırdan Active Directory" → "sifirdan-active-directory"
 * @param {string} metin
 */
export function slugla(metin) {
  // Türkçe harfleri KÜÇÜLTMEDEN ÖNCE çevir: 'I' Türkçe kurallarla 'ı' olur ve
  // sonraki filtrede elenir — "Entra ID" → "entra d" gibi bir sonuç çıkardı.
  const harita = {
    ç: 'c', Ç: 'c', ğ: 'g', Ğ: 'g', ı: 'i', I: 'i', İ: 'i',
    ö: 'o', Ö: 'o', ş: 's', Ş: 's', ü: 'u', Ü: 'u',
  };
  return metin
    .replace(/[çÇğĞıIİöÖşŞüÜ]/g, (h) => harita[h] ?? h)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/** @param {Date} d */
export function trTarih(d) {
  return new Intl.DateTimeFormat('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' }).format(d);
}

/** @param {Date} d */
export function trKisaTarih(d) {
  return new Intl.DateTimeFormat('tr-TR', { day: '2-digit', month: 'short', year: 'numeric' }).format(d);
}

/** @param {number} n */
export function sayi(n) {
  return new Intl.NumberFormat('tr-TR').format(n);
}
