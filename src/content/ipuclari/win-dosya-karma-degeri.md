---
baslik: "İndirdiğiniz dosyanın karma değerini doğrulayın"
ozet: "ISO veya kurulum dosyasının bozulmadığını ve doğru kaynaktan geldiğini tek komutla kontrol edin."
konu: "windows"
etiketler: ["guvenlik", "dogrulama"]
yayin: 2026-06-24
populerlik: 39
---

```powershell
Get-FileHash .\Windows.iso -Algorithm SHA256 | Format-List
```

Çıkan değeri üreticinin sitesindeki değerle karşılaştırın. Karşılaştırmayı gözle yapmak yerine:

```powershell
$beklenen = 'A1B2C3...'
(Get-FileHash .\Windows.iso -Algorithm SHA256).Hash -eq $beklenen
```

`True` dönerse dosya birebir aynıdır.

Karma değeri yalnızca bozulmayı değil, yolda değiştirilmiş olmayı da yakalar — bu yüzden beklenen değeri dosyayla aynı yerden değil, üreticinin resmî sayfasından alın.
