---
baslik: "AWS IAM: uzun ömürlü erişim anahtarlarını emekli etmek"
ozet: "Kod deposuna düşen anahtarların çoğu yıllardır dönmeyen IAM kullanıcılarına ait. Rol tabanlı erişime geçişin sırası."
konu: "aws"
etiketler: ["iam", "guvenlik", "kimlik"]
yayin: 2026-02-10
sure: 11
---

AWS'te en sık görülen güvenlik borcu, bir zamanlar "geçici olarak" oluşturulmuş IAM kullanıcılarıdır. Anahtarları hiç dönmemiştir, nerede kullanıldıkları belgelenmemiştir ve silinmeleri korkutucudur.

## Önce envanter

Kimlik bilgisi raporu, hesabınızdaki tüm kullanıcıların anahtar yaşını tek CSV'de verir:

```bash
aws iam generate-credential-report
aws iam get-credential-report --query Content --output text | base64 -d > kimlik-raporu.csv
```

`access_key_1_last_used_date` sütunu kritiktir. Hiç kullanılmamış anahtarlar en kolay silinenlerdir.

## Kullanılanları izleyin

Bir anahtarın nerede kullanıldığını CloudTrail söyler:

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=AKIA... \
  --max-results 25 \
  --query "Events[].{Zaman:EventTime, Olay:EventName, Kaynak:SourceIPAddress}" --output table
```

Kaynak IP size hangi sunucunun veya hangi ofisin kullandığını söyler. Bu, "bu anahtarı kim kullanıyor" sorusunun tek güvenilir cevabıdır.

## Geçiş sırası

1. **EC2 üzerindeki kullanımlar** → instance profile (rol). En kolay kazanç.
2. **CI/CD boru hatları** → OIDC federasyonu. GitHub Actions ve GitLab için anahtarsız erişim standarttır.
3. **İnsan kullanıcıları** → IAM Identity Center üzerinden geçici kimlik bilgisi.
4. **Kalan gerçek istisnalar** → 90 günlük döndürme takvimi ve belgelenmiş sahip.

## Devre dışı bırakın, silmeyin

```bash
aws iam update-access-key --user-name eski-kullanici \
  --access-key-id AKIA... --status Inactive
```

Bir şey kırılırsa tek komutla geri alırsınız. 30 gün sessizlik sonrası silin.

## Doğrulama adımı

Anahtarı pasife aldıktan sonra CloudTrail'de `errorCode = AuthFailure` kayıtlarını bir hafta izleyin. Hiç kayıt yoksa anahtar gerçekten ölüdür. Kayıt varsa hangi sistemin kullandığını bulmuşsunuz demektir — bu, tahmin etmekten çok daha iyi bir sonuç.
