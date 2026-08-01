---
baslik: "AWS Config ile uyum kurallarını işletmek"
ozet: "Denetim öncesi panik yerine sürekli ölçüm. Yönetilen kurallar, otomatik düzeltme ve maliyeti kontrol altında tutmak."
konu: "aws"
etiketler: ["config", "yonetisim", "uyum"]
yayin: 2026-05-26
sure: 10
---

AWS Config'in değeri raporlamada değil, **sapmayı olduğu anda görmekte**. Ama dikkatsiz açılırsa faturada hoş olmayan bir kalem üretir.

## Önce kayıt kapsamını daraltın

Varsayılan ayar tüm kaynak türlerini ve her değişikliği kaydeder. Küçük ortamlarda bile bu gereksizdir:

```bash
aws configservice put-configuration-recorder \
  --configuration-recorder name=varsayilan,roleARN=arn:aws:iam::<hesap>:role/config-role \
  --recording-group '{
    "allSupported": false,
    "resourceTypes": [
      "AWS::EC2::SecurityGroup", "AWS::EC2::Instance", "AWS::S3::Bucket",
      "AWS::IAM::Role", "AWS::IAM::User", "AWS::RDS::DBInstance"
    ]
  }'
```

Neyi denetlediğinizi bilmiyorsanız her şeyi kaydetmek yerine listeyi zamanla büyütün.

## Başlangıç için beş yönetilen kural

| Kural | Ne yakalar |
| --- | --- |
| `s3-bucket-public-read-prohibited` | Genel okunabilir kova |
| `iam-user-mfa-enabled` | MFA'sız konsol kullanıcısı |
| `ec2-volume-inuse-check` | Sahipsiz EBS birimi |
| `restricted-ssh` | 0.0.0.0/0 üzerinden 22 |
| `rds-storage-encrypted` | Şifresiz veritabanı |

```bash
aws configservice put-config-rule --config-rule '{
  "ConfigRuleName": "restricted-ssh",
  "Source": { "Owner": "AWS", "SourceIdentifier": "INCOMING_SSH_DISABLED" }
}'
```

## Otomatik düzeltmede acele etmeyin

Düzeltmeyi (remediation) ilk günden otomatik yapmak, üretimde bir bağlantıyı kesme riski taşır. Önce iki hafta manuel düzeltin, tekrarlayan ve güvenli olanları otomatiğe alın.

## Doğrulama adımı

Kuralları açtıktan bir hafta sonra uyumsuz kaynak sayısını çekin:

```bash
aws configservice describe-compliance-by-config-rule \
  --query "ComplianceByConfigRules[].{Kural:ConfigRuleName, Durum:Compliance.ComplianceType}" --output table
```

Sayı hiç değişmiyorsa ya kimse düzeltmiyordur ya da kural yanlış kapsamdadır. İkisi de aynı sonucu verir: pano yeşil sanılır, risk durur.
