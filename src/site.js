// Sitenin tek doğruluk kaynağı. İsim, alan adı ve imza burada değişir.
export const SITE = {
  name: 'bilgince',
  url: 'https://bilgince.dev',
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
    email: 'merhaba@bilgince.dev',
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

// Mega menüdeki konu sütunları. slug'lar /konu/<slug> adresine karşılık gelir.
export const KONULAR = [
  { slug: 'powershell', ad: 'PowerShell', ozet: 'Otomasyon, raporlama, zamanlanmış görev', grup: 'Altyapı' },
  { slug: 'windows-server', ad: 'Windows Server', ozet: 'Rol kurulumu, güncelleme, sertleştirme', grup: 'Altyapı' },
  { slug: 'sanallastirma', ad: 'Sanallaştırma', ozet: 'Hyper-V, depolama, checkpoint yönetimi', grup: 'Altyapı' },
  { slug: 'ag', ad: 'Ağ', ozet: 'Yönlendirme, VPN, güvenlik duvarı kuralları', grup: 'Ağ, kimlik ve süreklilik' },
  { slug: 'guvenlik', ad: 'Güvenlik & Entra ID', ozet: 'MFA, koşullu erişim, kimlik göçü', grup: 'Ağ, kimlik ve süreklilik' },
  { slug: 'yedekleme', ad: 'Yedekleme & kurtarma', ozet: 'Doğrulama rutini, RPO/RTO, tatbikat', grup: 'Ağ, kimlik ve süreklilik' },
];

export const POPULER_ARAMALAR = [
  'hesap kilitleniyor',
  'robocopy /MIR',
  '4740 olayı',
  'SMB over QUIC',
  'GPO yedekleme',
];

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
