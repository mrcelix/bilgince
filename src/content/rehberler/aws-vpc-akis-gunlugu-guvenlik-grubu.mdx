---
baslik: "VPC akış günlükleriyle güvenlik gruplarını temizlemek"
ozet: "0.0.0.0/0 kuralını silmeden önce oradan ne geçtiğini ölçün. Athena ile bir haftalık trafiği okumak."
konu: "aws"
etiketler: ["vpc", "guvenlik", "athena"]
yayin: 2026-03-24
sure: 12
---

Güvenlik grubu kuralları zamanla genişler, hiç daralmaz. Daraltmanın tek güvenli yolu ölçmektir.

## Akış günlüklerini S3'e yazın

```bash
aws ec2 create-flow-logs \
  --resource-type VPC --resource-ids vpc-0abc123 \
  --traffic-type ALL \
  --log-destination-type s3 \
  --log-destination arn:aws:s3:::akis-gunlukleri-kovasi \
  --max-aggregation-interval 60
```

CloudWatch Logs yerine S3 seçmek maliyeti belirgin biçimde düşürür ve Athena ile sorgulamayı kolaylaştırır.

## Athena tablosu ve sorgu

Tabloyu oluşturduktan sonra asıl soru şu: **hangi kaynaklardan hangi portlara kabul edilen trafik var?**

```sql
SELECT srcaddr, dstaddr, dstport, protocol, count(*) AS akis
FROM vpc_akis_gunlukleri
WHERE action = 'ACCEPT'
  AND date >= current_date - interval '7' day
GROUP BY srcaddr, dstaddr, dstport, protocol
ORDER BY akis DESC
LIMIT 100;
```

Bu tablo yeni kural setinizin taslağıdır. Listede olmayan portu açmayın.

## Reddedilenlere de bakın

```sql
SELECT srcaddr, dstport, count(*) AS deneme
FROM vpc_akis_gunlukleri
WHERE action = 'REJECT' AND date >= current_date - interval '7' day
GROUP BY srcaddr, dstport
ORDER BY deneme DESC
LIMIT 50;
```

Bu liste iki şeyi gösterir: internetten gelen tarama gürültüsü ve **yanlışlıkla engellediğiniz iç trafik**. İkincisi genelde birinin sessizce çözmeye çalıştığı bir sorundur.

## Doğrulama adımı

Daraltılmış kuralları uyguladıktan sonra `REJECT` sorgusunu 48 saat sonra tekrar çalıştırın. İç ağ aralıklarınızdan (10.x, 172.16.x) gelen yeni reddedilmeler varsa bir şeyi kırmışsınız demektir; dışarıdan gelenler ise beklenen gürültüdür. Bu ikisini ayırmadan kuralı doğru saymayın.
