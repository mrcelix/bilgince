---
baslik: "S3'te genel erişimi kapatmanın doğru sırası"
ozet: "Block Public Access'i düşünmeden açmak statik site sunan kovaları kırar. Önce ölçüp sonra kapatmanın yolu."
konu: "aws"
etiketler: ["s3", "guvenlik", "veri"]
yayin: 2026-03-03
sure: 8
---

"Bütün kovaları kapatın" talimatı doğru ama uygulanışı çoğu zaman yanlış: hesap düzeyinde Block Public Access açılır ve ertesi gün birkaç uygulama çalışmaz hâle gelir.

## Önce hangi kovalar açık?

```bash
for k in $(aws s3api list-buckets --query "Buckets[].Name" --output text); do
  durum=$(aws s3api get-public-access-block --bucket "$k" \
    --query "PublicAccessBlockConfiguration.BlockPublicAcls" --output text 2>/dev/null || echo "YOK")
  echo "$k -> $durum"
done
```

`YOK` veya `False` dönenler incelenecek listedir.

## Sonra gerçekten genel mi?

Bir kovanın genel erişim engeli olmaması, genel olduğu anlamına gelmez. IAM Access Analyzer bunu kesin söyler:

```bash
aws accessanalyzer create-analyzer --analyzer-name hesap-analiz --type ACCOUNT
aws accessanalyzer list-findings --analyzer-arn <arn> \
  --query "findings[?resourceType=='AWS::S3::Bucket'].{Kova:resource, Durum:status}" --output table
```

## Kapatma sırası

1. Kova düzeyinde açın, hesap düzeyinde değil. Böylece etki alanı dar kalır.
2. Statik site sunan kovalar için genel erişim yerine **CloudFront + Origin Access Control** kullanın; kova özel kalır, dağıtım genel olur.
3. Hepsi geçtikten sonra hesap düzeyinde açın ki yeni kovalar varsayılan olarak kapalı gelsin.

```bash
aws s3api put-public-access-block --bucket kova-adi \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

## Doğrulama adımı

Kapattıktan sonra kimliksiz bir istekle deneyin:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://kova-adi.s3.amazonaws.com/test.txt
```

`403` beklenen sonuçtur. `200` alıyorsanız kova politikası hâlâ genel erişime izin veriyordur — Block Public Access, kova politikasındaki açık izni her zaman geçersiz kılmaz; politikayı da okuyun.
