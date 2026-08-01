---
baslik: "AWS faturasında en hızlı üç kazanç"
ozet: "gp2'den gp3'e geçiş, sahipsiz EBS birimleri ve gereksiz NAT Gateway. Mimariye dokunmadan alınabilecek üç sonuç."
konu: "aws"
etiketler: ["maliyet", "ebs", "vpc"]
yayin: 2026-01-20
sure: 9
---

Rezervasyon ve Savings Plan konuşmasına girmeden önce yapılacak üç iş var. Üçü de mimariyi değiştirmez, üçü de aynı gün uygulanabilir.

## 1. gp2 → gp3

gp3 birimleri gp2'ye göre gigabayt başına belirgin şekilde ucuzdur ve temel performansı boyuttan bağımsızdır. Dönüşüm çevrimiçi yapılır, makine kapanmaz.

```bash
aws ec2 describe-volumes --filters Name=volume-type,Values=gp2 \
  --query "Volumes[].{Id:VolumeId, GB:Size, Makine:Attachments[0].InstanceId}" --output table

aws ec2 modify-volume --volume-id vol-0abc123 --volume-type gp3
```

Yalnız dikkat: gp2'de büyük birimler boyutları sayesinde yüksek IOPS alır. 1 TB'ın üzerindeki birimlerde gp3'e geçerken `--iops` değerini elle vermezseniz performans düşebilir.

## 2. Sahipsiz EBS birimleri ve eski anlık görüntüler

```bash
aws ec2 describe-volumes --filters Name=status,Values=available \
  --query "Volumes[].{Id:VolumeId, GB:Size, Olusturma:CreateTime}" --output table
```

`available` durumu "hiçbir makineye bağlı değil" demektir. Silmeden önce anlık görüntü alın; görüntü, birimin kendisinden çok daha ucuza durur.

## 3. NAT Gateway sayısı

NAT Gateway hem saatlik hem de veri işleme başına ücretlendirilir ve genelde fark edilmeden çoğalır. Üç availability zone'da üç NAT Gateway yüksek erişilebilirlik demektir — ama test ortamında buna gerek yoktur.

```bash
aws ec2 describe-nat-gateways \
  --query "NatGateways[?State=='available'].{Id:NatGatewayId, VPC:VpcId, AltAg:SubnetId}" --output table
```

Ayrıca S3 ve DynamoDB'ye giden trafik için **VPC Gateway Endpoint** ücretsizdir; onu eklemek NAT üzerinden akan veriyi ciddi biçimde azaltır.

## Doğrulama adımı

Değişikliklerden bir hafta sonra Cost Explorer'da `USAGE_TYPE` kırılımına bakın ve `NatGateway-Bytes` ile `EBS:VolumeUsage.gp2` kalemlerini önceki haftayla karşılaştırın. Düşüş yoksa değişiklik yanlış hesapta ya da yanlış bölgede yapılmıştır — önce bunu doğrulayın, yeni iş açmayın.
