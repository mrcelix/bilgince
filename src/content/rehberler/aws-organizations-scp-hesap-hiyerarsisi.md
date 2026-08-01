---
baslik: "AWS Organizations ve SCP: hesap hiyerarşisini kurmak"
ozet: "Tek hesapta her şeyi tutmak ucuz görünür, pahalıya patlar. Organizasyon birimleri ve servis kontrol politikalarıyla sade bir düzen."
konu: "aws"
etiketler: ["organizations", "yonetisim", "guvenlik"]
yayin: 2026-04-14
sure: 12
---

Hesap sınırı, AWS'teki en güçlü izolasyon sınırıdır. IAM politikası yanlış yazılabilir; hesap sınırı yanlış yazılamaz.

## Sade bir organizasyon birimi ağacı

```
Kök
├── Altyapi        → ağ, günlük arşivi, güvenlik araçları
├── IsYukleri
│   ├── Uretim
│   └── Test
└── SanalAlan      → denemeler, bütçe sınırlı
```

```bash
aws organizations create-organizational-unit --parent-id r-abcd --name IsYukleri
aws organizations create-organizational-unit --parent-id ou-abcd-1111 --name Uretim
```

## SCP: izin vermez, izni sınırlar

En sık yanılgı budur. SCP kimseye yetki **vermez**; yalnızca verilebilecek yetkinin tavanını belirler. Kullanıcının IAM politikası da izin vermiyorsa erişim yine olmaz.

Kullanılmayan bölgeleri kapatmak, en yüksek getirili ilk SCP'dir — hem maliyeti hem saldırı yüzeyini düşürür:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "NotAction": ["iam:*", "organizations:*", "sts:*", "cloudfront:*", "route53:*", "support:*"],
    "Resource": "*",
    "Condition": {
      "StringNotEquals": { "aws:RequestedRegion": ["eu-central-1", "eu-west-1"] }
    }
  }]
}
```

Genel (global) hizmetleri `NotAction` ile dışarıda bırakmayı unutursanız IAM'e erişimi kaybedersiniz. Bu, SCP ile yapılan en pahalı hatadır.

## Sırayla uygulayın

Politikayı önce `SanalAlan` birimine bağlayın, bir hafta izleyin, sonra `Test`, en son `Uretim`. Kök düzeyine bağlamak son adımdır; ilk adım değil.

## Doğrulama adımı

Politikayı bağladıktan sonra kapsanan hesapta yasaklı bölgede kaynak açmayı deneyin:

```bash
aws ec2 describe-instances --region us-east-1
```

`AccessDeniedException` beklenen sonuçtur. Ardından izinli bölgede aynı komutu çalıştırın — çalışmalı. İkisi de doğrulanmadan bir sonraki organizasyon birimine geçmeyin.
