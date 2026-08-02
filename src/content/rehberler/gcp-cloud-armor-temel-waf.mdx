---
baslik: "Cloud Armor ile temel WAF ve hız sınırlama"
ozet: "Önce önizleme modu, sonra engelleme. Hazır kural setlerini üretimi kırmadan devreye almanın sırası."
konu: "google-cloud"
etiketler: ["guvenlik", "waf", "yuk-dengeleyici"]
yayin: 2026-08-01
sure: 10
---

Cloud Armor, HTTP(S) yük dengeleyicinin önünde çalışır. Hazır kural setleri güçlüdür ama doğrudan `deny` modunda açılırsa meşru trafiği de keser — özellikle dosya yükleyen ve zengin metin gönderen uygulamalarda.

## Politika ve önizleme

```bash
gcloud compute security-policies create web-koruma \
  --description="Üretim web koruması"

gcloud compute security-policies rules create 1000 \
  --security-policy=web-koruma \
  --expression="evaluatePreconfiguredExpr('sqli-v33-stable')" \
  --action=deny-403 \
  --preview
```

`--preview` ile kural değerlendirilir ama uygulanmaz; sonuç yalnızca günlüğe yazılır.

## Önizleme sonuçlarını okuyun

```
resource.type="http_load_balancer"
jsonPayload.enforcedSecurityPolicy.outcome="ACCEPT"
jsonPayload.previewSecurityPolicy.outcome="DENY"
```

Bu filtre, "önizleme açık olmasaydı engellenecek olan" istekleri verir. İçlerinde kendi uygulamanızın normal istekleri varsa hassasiyeti düşürmeniz ya da o yola istisna yazmanız gerekir.

## Hız sınırlama

Oturum açma uç noktası için IP başına sınır, kaba kuvvet denemelerini belirgin biçimde azaltır:

```bash
gcloud compute security-policies rules create 2000 \
  --security-policy=web-koruma \
  --expression="request.path.matches('/giris')" \
  --action=rate-based-ban \
  --rate-limit-threshold-count=20 \
  --rate-limit-threshold-interval-sec=60 \
  --ban-duration-sec=600 \
  --conform-action=allow --exceed-action=deny-429 \
  --enforce-on-key=IP
```

## Yayına alma

```bash
gcloud compute security-policies rules update 1000 \
  --security-policy=web-koruma --no-preview
```

## Doğrulama adımı

Yayına aldıktan sonra iki test: uygulamanın normal bir akışını baştan sona çalıştırın (**geçmeli**) ve zararsız bir SQL enjeksiyon dizgesini sorgu parametresi olarak gönderin — **403 dönmeli**. Ardından bir hafta boyunca `outcome="DENY"` kayıtlarında kendi kullanıcı IP aralıklarınızı arayın; orada çıkan her kayıt meşru trafiği kestiğinizin işaretidir.
