---
baslik: "Cloud Logging: log router ile hem maliyeti hem gürültüyü düşürmek"
ozet: "Her şeyi saklamak pahalı, hiçbir şeyi saklamamak riskli. Dışlama filtreleri ve arşiv kovasıyla dengeli bir kurulum."
konu: "google-cloud"
etiketler: ["logging", "maliyet", "izleme"]
yayin: 2026-04-21
sure: 9
---

Cloud Logging faturası çoğu projede sessizce büyür. Sebep genelde tek bir gürültülü kaynaktır: yük dengeleyici erişim günlükleri ya da sağlık kontrolü istekleri.

## Kim ne kadar yazıyor?

```bash
gcloud logging read 'timestamp >= "2026-04-01T00:00:00Z"' \
  --limit=0 --format=none 2>/dev/null
```

Daha pratiği: Logs Explorer'da **Log fields** panelinden `logName` kırılımına bakmak. En üstteki üç kaynak genelde faturanın çoğunu üretir.

## Dışlama filtresi

Sağlık kontrollerini saklamanın hiçbir değeri yoktur:

```bash
gcloud logging sinks update _Default \
  --add-exclusion=name=saglik-kontrolu,filter='
    resource.type="http_load_balancer"
    httpRequest.userAgent=~"GoogleHC"
  '
```

Dışlama, günlüğün üretilmesini engellemez; **saklanmasını** engeller. Yani gerektiğinde filtreyi kaldırıp yeniden toplamaya başlayabilirsiniz.

## Uzun süreli saklama için ayrı hedef

Denetim günlüklerini pahalı log kovasında yıllarca tutmak yerine Cloud Storage'a yönlendirin ve yaşam döngüsü kuralıyla soğuk katmana indirin:

```bash
gcloud logging sinks create denetim-arsiv \
  storage.googleapis.com/sirket-denetim-arsiv \
  --log-filter='logName:"cloudaudit.googleapis.com"'
```

Sink oluşturduktan sonra dönen servis hesabına kovada yazma yetkisi vermeyi unutmayın — en sık atlanan adım budur.

## Saklama süresini kısaltın

`_Default` kovası varsayılan 30 gün saklar. Uygulama günlüklerinde 7–14 gün çoğu ekip için yeterlidir; denetim günlükleri zaten ayrı hedefe gidiyordur.

## Doğrulama adımı

Değişikliklerden bir hafta sonra faturada `Logging` kalemini önceki haftayla karşılaştırın **ve** bir olay tatbikatı yapın: geçen haftaya ait bir hatayı arayın. Bulamıyorsanız fazla kısmışsınız demektir. Maliyet düşüşü tek başına başarı değildir; olayı hâlâ araştırabiliyor olmanız gerekir.
