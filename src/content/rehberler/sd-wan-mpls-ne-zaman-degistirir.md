---
baslik: "SD-WAN, MPLS'i ne zaman gerçekten değiştirir?"
ozet: "Her şube için doğru cevap aynı değil. Karar, uygulama karışımına ve şubenin taşıdığı riske göre verilir."
konu: "sd-wan"
etiketler: ["mpls", "mimari", "sube"]
yayin: 2026-01-06
sure: 11
---

SD-WAN satış sunumlarının çoğu "MPLS'i kapatın, internete geçin" der. Gerçekte çoğu kurum karma bir yapıda kalır ve bu bir başarısızlık değildir.

## MPLS'in gerçekten verdiği şey

MPLS pahalıdır ama iki şeyi sözleşmeyle taahhüt eder: **gecikme/jitter sınırı** ve **paket kaybı sınırı**. İnternet devresi bunu taahhüt etmez; ortalamada iyi, kuyrukta değişkendir.

Şu iş yükleri kuyruk değişkenliğinden doğrudan etkilenir:
- Ses ve video (özellikle çağrı merkezi)
- Sanal masaüstü (VDI)
- Gerçek zamanlı üretim/otomasyon protokolleri

## Karar tablosu

| Şube profili | Öneri |
| --- | --- |
| Küçük satış ofisi, çoğu trafik SaaS | Çift internet, MPLS yok |
| Çağrı merkezi | MPLS + internet (hibrit), ses MPLS'te |
| Üretim tesisi, OT trafiği | MPLS veya özel devre; internet yedek |
| Depo, düşük kullanıcı | Tek internet + 5G yedek |
| Merkez/veri merkezi | Çift devre, farklı operatör |

## Geçişte en çok yapılan hata

Tek operatörden iki devre almak. Fiziksel yol aynıysa, iki devre bir kazma darbesiyle birlikte gider. Sözleşmede **farklı son mil (last mile)** talep edin ve teslimden sonra doğrulayın.

## Maliyet karşılaştırması dürüst olsun

MPLS maliyetini kaldırırken şunları eklemeyi unutmayın: SD-WAN abonelik/lisans, cihaz yenileme, güvenlik katmanı (SASE), yedek 5G hatların veri paketi. Net kazanç genelde vardır ama sunumdaki kadar büyük değildir.

## Doğrulama adımı

Karara varmadan önce şubede iki hafta ölçüm yapın: iş saatlerinde gecikme, jitter ve paket kaybının **95. yüzdelik** değerlerini kaydedin. Ortalama değil, yüzdelik önemlidir — kullanıcıların şikâyet ettiği an ortalamanın değil, kuyruğun anıdır. Bu iki haftalık veri olmadan yapılan MPLS iptali, sonradan geri alınması en pahalı karardır.
