---
baslik: "Google Cloud'da bütçe uyarıları ve maliyeti sahiplendirmek"
ozet: "Fatura geldiğinde şaşırmamak için bütçe, etiket disiplini ve BigQuery'ye fatura dışa aktarımı."
konu: "google-cloud"
etiketler: ["maliyet", "bigquery", "yonetisim"]
yayin: 2026-03-31
sure: 10
---

GCP'de maliyet sürpriziyle karşılaşmanın en yaygın sebebi, bütçe uyarısının hiç kurulmamış olmasıdır. İkinci sebebi, kurulmuş ama kimseye gitmemesidir.

## Bütçe ve eşikler

```bash
gcloud billing budgets create \
  --billing-account=012345-6789AB-CDEF01 \
  --display-name="uretim-aylik" \
  --budget-amount=5000TRY \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0 \
  --filter-projects="projects/sirket-uretim-web"
```

%50 eşiği en değerlisidir: ayın yarısında %50'yi geçtiyseniz sorun büyümeden görünür.

## Uyarıyı e-postadan çıkarın

Bütçe uyarısını Pub/Sub'a bağlayıp oradan sohbet kanalına düşürmek, e-postadan çok daha etkilidir. E-posta uyarıları, en çok ihtiyaç duyulduğu ay okunmaz.

## Fatura verisini BigQuery'ye aktarın

Konsoldaki rapor ekranı bir noktadan sonra yetmez. Dışa aktarım açıldıktan sonra:

```sql
SELECT
  service.description AS hizmet,
  (SELECT value FROM UNNEST(labels) WHERE key = 'ortam') AS ortam,
  ROUND(SUM(cost), 2) AS maliyet
FROM `sirket.fatura.gcp_billing_export_v1_XXXX`
WHERE DATE(usage_start_time) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
GROUP BY hizmet, ortam
ORDER BY maliyet DESC
LIMIT 25;
```

`ortam` sütununda `null` görünen satırlar etiketlenmemiş kaynaklardır. Bu, maliyet raporunun değil yönetişimin sorunudur.

## Etiketi zorunlu kılın

Etiketsiz kaynak, sahipsiz maliyettir. Kuruluş politikasıyla ya da dağıtım hattında bir kontrolle etiketi zorunlu hâle getirin; rapordan önce bunu çözün.

## Doğrulama adımı

Bir ay sonra yukarıdaki sorguyu tekrar çalıştırın ve `null` ortam satırının toplam maliyet içindeki payını ölçün. Bu oran düşmüyorsa etiket zorunluluğu gerçekte işlemiyordur — raporu güzelleştirmek yerine oraya bakın.
