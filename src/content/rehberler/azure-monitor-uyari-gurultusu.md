---
baslik: "Azure Monitor uyarı gürültüsünü azaltmak"
ozet: "Kimsenin okumadığı uyarı, uyarı değildir. Eşik, süre ve gruplama ayarlarıyla gerçekten müdahale gerektiren olayları ayırmak."
konu: "azure"
etiketler: ["izleme", "operasyon"]
yayin: 2026-04-07
sure: 8
---

Nöbet telefonuna gecede kırk bildirim düşüyorsa ekip onları okumayı bırakmıştır. Gürültü, izlemenin olmamasından daha tehlikelidir: sistemin izlendiği yanılsamasını üretir.

## Üç ayar, gürültünün çoğunu keser

**1. Değerlendirme penceresini uzatın.** CPU'nun bir dakika %90 olması olay değildir. Beş dakikalık ortalama üzerinden değerlendirin.

**2. Ardışık ihlal sayısı isteyin.** Azure Monitor'da bir uyarı kuralı `Number of violations` / `Evaluation periods` ayarıyla "son 5 değerlendirmenin 3'ünde ihlal varsa tetikle" diyebilir. Anlık sıçramalar böylece elenir.

**3. Otomatik çözülmeyi açın.** `Auto-resolve` kapalıysa uyarılar birikir ve panoya bakan kişi neyin güncel olduğunu anlamaz.

```bash
az monitor metrics alert create \
  --name "cpu-yuksek-uretim" \
  --resource-group uretim-rg \
  --scopes "/subscriptions/<id>/resourceGroups/uretim-rg/providers/Microsoft.Compute/virtualMachines/vm01" \
  --condition "avg Percentage CPU > 85" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --auto-mitigate true \
  --severity 2
```

## Uyarı işleme kuralları

Planlı bakım penceresinde uyarı almak istemezsiniz. Kuralları tek tek kapatmak yerine **alert processing rule** ile o zaman aralığını susturun:

```bash
az monitor alert-processing-rule create \
  --name "bakim-penceresi-pazar" \
  --rule-type RemoveAllActionGroups \
  --scopes "/subscriptions/<id>/resourceGroups/uretim-rg" \
  --resource-group uretim-rg \
  --schedule-recurrence-type Weekly \
  --schedule-recurrence Sunday \
  --schedule-start-time "02:00:00" --schedule-end-time "05:00:00"
```

## Doğrulama adımı

Bir ay sonra tetiklenen uyarıları çekin ve her biri için tek soruyu sorun: **bu uyarı bir eylemle sonuçlandı mı?**

```kusto
AlertsManagementResources
| where properties.essentials.startDateTime > ago(30d)
| summarize Adet = count() by tostring(properties.essentials.alertRule)
| order by Adet desc
```

En çok tetiklenen üç kural hiçbir eyleme yol açmadıysa onlar uyarı değil, ölçüm. Panoya taşıyın, telefondan düşürün.
