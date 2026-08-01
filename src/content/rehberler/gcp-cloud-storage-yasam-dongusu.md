---
baslik: "Cloud Storage yaşam döngüsü kurallarıyla depolama maliyetini düşürmek"
ozet: "Nearline, Coldline ve Archive katmanları arasında otomatik geçiş — ve erken silme cezasına yakalanmadan bunu yapmak."
konu: "google-cloud"
etiketler: ["storage", "maliyet"]
yayin: 2026-06-23
sure: 8
---

Cloud Storage'da veri, oluşturulduğu katmanda kalır ve kimse ona dokunmaz. Oysa yedek arşivinin altı ay sonra Standard katmanında durmasının hiçbir gerekçesi yoktur.

## Katmanların gerçek maliyeti

Ucuz katmanlar depolamada ucuz, **erişimde pahalıdır**. Ayrıca minimum saklama süreleri vardır: Nearline 30, Coldline 90, Archive 365 gün. Bu süreden önce silerseniz kalan süre kadar ücret ödersiniz — "erken silme cezası" budur ve yaşam döngüsü kuralı yazarken en çok gözden kaçan detaydır.

## Kural dosyası

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": { "type": "SetStorageClass", "storageClass": "NEARLINE" },
        "condition": { "age": 30, "matchesStorageClass": ["STANDARD"] }
      },
      {
        "action": { "type": "SetStorageClass", "storageClass": "COLDLINE" },
        "condition": { "age": 120, "matchesStorageClass": ["NEARLINE"] }
      },
      {
        "action": { "type": "Delete" },
        "condition": { "age": 1095 }
      }
    ]
  }
}
```

```bash
gcloud storage buckets update gs://sirket-yedek --lifecycle-file=yasam-dongusu.json
```

Geçiş eşiklerini minimum saklama sürelerinden **uzun** tutun: 30 günde Nearline'a geçen bir nesneyi 120 günde Coldline'a taşımak güvenlidir, 45 günde taşımak ceza üretir.

## Silme kuralına dikkat

`Delete` eylemi geri alınamaz. Kovada nesne sürümleme açıksa `numNewerVersions` koşuluyla yalnızca eski sürümleri silmek çok daha güvenlidir.

## Doğrulama adımı

Kuralı uyguladıktan bir ay sonra katman dağılımını ölçün:

```bash
gcloud storage ls --recursive --long gs://sirket-yedek | head -20
```

Hiçbir nesne katman değiştirmediyse ya yaş koşulu henüz dolmamıştır ya da kural yanlış kovaya bağlanmıştır. Faturaya bakmadan önce bunu doğrulayın.
