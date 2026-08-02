---
baslik: "VPC Service Controls ile veri sızıntısını sınırlamak"
ozet: "IAM 'kim erişebilir' sorusunu çözer, 'veri nereye çıkabilir' sorusunu çözmez. Servis çevresi bunun içindir."
konu: "google-cloud"
etiketler: ["guvenlik", "veri", "ag"]
yayin: 2026-05-12
sure: 11
---

Yetkili bir kullanıcı, yetkili olduğu veriyi kendi kişisel projesindeki bir kovaya kopyalayabilir. IAM bunu engellemez çünkü kullanıcı gerçekten yetkilidir. VPC Service Controls, verinin çıkabileceği sınırı çizer.

## Çevre oluşturmadan önce: kuru mod

Çevreyi doğrudan uygulamak, bilmediğiniz entegrasyonları keser. Önce `dry-run` ile çalıştırın:

```bash
gcloud access-context-manager perimeters create uretim-cevre \
  --title="Üretim veri çevresi" \
  --resources=projects/123456789 \
  --restricted-services=storage.googleapis.com,bigquery.googleapis.com \
  --policy=987654321 \
  --perimeter-type=regular \
  --dry-run
```

## İhlalleri okuyun

Kuru modda gerçek engelleme olmaz, ama günlüğe kayıt düşer:

```
protoPayload.metadata.dryRun="true"
protoPayload.metadata.@type="type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata"
```

Çıkan her kayıt, çevre açıldığında kırılacak bir erişimdir. Bu liste, erişim düzeyleri (access levels) ve giriş/çıkış kurallarıyla ele alacağınız iş listesidir.

## Sık karşılaşılan üç kırılma

1. **CI/CD** — dağıtım hattı çevre dışından çalışıyorsa giriş kuralı gerekir.
2. **BigQuery dış sorguları** — başka projedeki veri kümesine erişim engellenir.
3. **Yönetim konsolu** — kurumsal ağ dışından erişen yöneticiler için erişim düzeyi tanımlayın.

## Yayına alma

```bash
gcloud access-context-manager perimeters update uretim-cevre \
  --policy=987654321 --enforce-dry-run-config
```

## Doğrulama adımı

Çevre yayına alındıktan sonra iki test yapın: çevre içindeki bir makineden korumalı kovaya erişin — **çalışmalı**. Çevre dışındaki kişisel bir projeden aynı kovayı listeleyin — **`VPC Service Controls` hatası dönmeli**. İkinci test yapılmadan çevre çalışıyor sayılamaz; kuru modda kalmış bir çevre hiçbir şey korumaz.
