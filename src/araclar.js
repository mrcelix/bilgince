// Araç kütüğü: hem /araclar dizini hem başlıktaki Araçlar menüsü buradan
// besleniyor. Yeni bir araç eklerken sayfayı yazıp bu listeye bir satır
// eklemek yeterli — menü, dizin ve sayaçlar kendiliğinden güncellenir.
export const ARACLAR = [
  {
    slug: 'parola',
    ad: 'Parola üreteci',
    ozet: 'Kriptografik rastgelelikle parola ve Türkçe geçiş cümlesi; entropi ve kırılma süresi yanında.',
    ikon: 'kalkan',
    etiket: 'yeni',
    cevrimici: false,
  },
  {
    slug: 'sizinti-kontrol',
    ad: 'Parola sızıntı kontrolü',
    ozet: 'Parolanız sızıntı veri tabanında geçiyor mu? Yalnızca özetin ilk 5 hanesi sorulur.',
    ikon: 'kalkan',
    etiket: 'yeni',
    cevrimici: true,
  },
  {
    slug: 'wifi-qr',
    ad: 'Wi-Fi QR kod üreteci',
    ozet: 'Misafir ağı için taranabilir QR ve yazdırılabilir kart; QR tarayıcıda üretilir.',
    ikon: 'kure',
    etiket: 'yeni',
    cevrimici: false,
  },
  {
    slug: 'paylasim-karti',
    ad: 'Paylaşım kartı üreteci',
    ozet: 'Bir adresin temasını okuyup sosyal medya görselleri üretir; 14 stil, dört boyut.',
    ikon: 'kutu',
    etiket: '',
    cevrimici: true,
  },
];

export const aracBul = (slug) => ARACLAR.find((a) => a.slug === slug);
