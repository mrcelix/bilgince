---
baslik: "CloudWatch alarm gürültüsünü azaltmak"
ozet: "Composite alarm, anomali algılama ve eksik veri davranışı. Nöbetçiyi gece uyandıran şeyi gerçekten olaylara indirgemek."
konu: "aws"
etiketler: ["cloudwatch", "izleme", "operasyon"]
yayin: 2026-07-07
sure: 9
---

CloudWatch'ta alarm kurmak kolay, alarmı anlamlı tutmak zordur. Üç mekanizma gürültünün çoğunu keser.

## 1. Eksik veri davranışı

Varsayılan `missing` davranışı, metrik gelmediğinde alarmı tetikleyebilir. Ölçeklenen ortamlarda makine kapandığında metrik durur ve alarm çalar — oysa olay yoktur.

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "cpu-yuksek-web" \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 300 --evaluation-periods 3 --datapoints-to-alarm 2 \
  --threshold 85 --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions arn:aws:sns:eu-central-1:<hesap>:nobet
```

`--evaluation-periods 3 --datapoints-to-alarm 2` kombinasyonu, "son 15 dakikanın 10 dakikasında yüksekse" demektir. Anlık sıçramalar böylece elenir.

## 2. Composite alarm

Tek başına anlamsız iki sinyal, birlikte olaydır. Yalnızca CPU yüksekken **ve** hata oranı artmışken uyarın:

```bash
aws cloudwatch put-composite-alarm \
  --alarm-name "web-gercek-sorun" \
  --alarm-rule "ALARM(cpu-yuksek-web) AND ALARM(5xx-orani-yuksek)" \
  --alarm-actions arn:aws:sns:eu-central-1:<hesap>:nobet
```

Bileşenleri bildirimsiz bırakın; yalnızca bileşik alarm telefon çalsın.

## 3. Anomali algılama

Sabit eşik, iş yükü mevsimselse hep yanlıştır. Anomali algılama bandı, geçmiş desene göre eşiği kendisi belirler. Cuma akşamı düşen trafiğe alarm üretmemesi bu yüzdendir.

## Doğrulama adımı

Bir ay sonra alarm geçmişini çekin ve her alarm için "bir eylemle sonuçlandı mı" sorusunu sorun:

```bash
aws cloudwatch describe-alarm-history --history-item-type StateUpdate \
  --start-date 2026-06-01T00:00:00Z --end-date 2026-07-01T00:00:00Z \
  --query "AlarmHistoryItems[].AlarmName" --output text | tr '\t' '\n' | sort | uniq -c | sort -rn
```

En üstteki üç alarm hiçbir müdahaleye yol açmadıysa onları panoya taşıyın. Nöbet telefonunda yalnızca insan gerektiren şeyler kalmalı.
