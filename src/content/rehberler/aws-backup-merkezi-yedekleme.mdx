---
baslik: "AWS Backup ile merkezi yedekleme ve geri dönüş testi"
ozet: "Her hizmetin kendi anlık görüntü mantığı yerine tek plan. Etiketle kapsama, çapraz hesap kopyası ve aylık kurtarma provası."
konu: "aws"
etiketler: ["yedekleme", "sureklilik"]
yayin: 2026-05-05
sure: 11
seri: "Yedekleme doğrulama rutini"
seriSira: 4
---

EBS anlık görüntüsü ayrı, RDS anlık görüntüsü ayrı, EFS ayrı yönetiliyorsa hangi verinin ne kadar korunduğunu kimse bilmiyordur. AWS Backup bunları tek plana bağlar.

## Kasa ve plan

```bash
aws backup create-backup-vault --backup-vault-name uretim-kasa

aws backup create-backup-plan --backup-plan '{
  "BackupPlanName": "uretim-gunluk",
  "Rules": [{
    "RuleName": "gunluk-35-gun",
    "TargetBackupVaultName": "uretim-kasa",
    "ScheduleExpression": "cron(0 2 ? * * *)",
    "StartWindowMinutes": 60,
    "Lifecycle": { "DeleteAfterDays": 35 }
  }]
}'
```

## Etiketle kapsama

Kaynakları tek tek eklemek sürdürülemez. Etikete göre seçim yaparsanız yeni kaynak doğru etiketi taşıdığı anda korumaya girer:

```bash
aws backup create-backup-selection --backup-plan-id <plan-id> --backup-selection '{
  "SelectionName": "etiketli-uretim",
  "IamRoleArn": "arn:aws:iam::<hesap>:role/service-role/AWSBackupDefaultServiceRole",
  "ListOfTags": [{ "ConditionType": "STRINGEQUALS", "ConditionKey": "Ortam", "ConditionValue": "uretim" }]
}'
```

Bu yaklaşımın bedeli şudur: etiketi olmayan kaynak sessizce korumasız kalır. Bu yüzden etiket zorunluluğunu SCP veya Config kuralıyla desteklemelisiniz.

## Çapraz hesap kopyası

Fidye yazılımı senaryosunda aynı hesapta duran yedek yedek değildir. Kopyayı ayrı bir hesaptaki kasaya alın ve o kasayı **vault lock** ile değiştirilemez yapın.

## Doğrulama adımı

Ayda bir, rastgele bir kurtarma noktasını **izole bir VPC'ye** geri yükleyin ve şu üçünü ölçün: geri yükleme süresi, kurtarma noktası yaşı, açılan sistemde doğrulanan servis sayısı. Üretim VPC'sine geri yüklemeyin — aynı IP ve aynı isim, testi olaya çevirir.
