---
baslik: "GCP IAM: temel roller neden tehlikeli"
ozet: "Editor rolü bir kişiye verilen en kolay ve en pahalı karardır. Önceden tanımlı rollerle daraltmanın pratik yolu."
konu: "google-cloud"
etiketler: ["iam", "guvenlik", "yonetisim"]
yayin: 2026-02-17
sure: 9
---

`roles/owner`, `roles/editor`, `roles/viewer` — bunlara **temel roller** denir ve Google bile üretimde kullanılmamasını önerir. Sorun şu: `editor` neredeyse her şeyi değiştirebilir, ama denetimde "kim neyi değiştirebilir" sorusuna cevap veremezsiniz.

## Mevcut durumu görün

```bash
gcloud projects get-iam-policy sirket-uretim-web \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/editor OR bindings.role:roles/owner" \
  --format="table(bindings.role, bindings.members)"
```

Bu listede insan olmayan hesaplar (servis hesapları) varsa öncelik onlardır — bir servis hesabının `editor` olması, ele geçirildiğinde projenin tamamı demektir.

## Gerçekten hangi izinler kullanılıyor?

Policy Analyzer ve öneri motoru, son 90 günün kullanımına bakarak daha dar rol önerir:

```bash
gcloud recommender recommendations list \
  --project=sirket-uretim-web \
  --location=global \
  --recommender=google.iam.policy.Recommender \
  --format="table(content.overview.member, content.overview.removedRole, content.overview.addedRoles)"
```

Bu çıktı, tartışmayı fikirden veriye taşır: "sana editor lazım" yerine "son 90 günde şu 6 izni kullandın".

## Daraltma sırası

1. Servis hesapları (en yüksek risk, en düşük itiraz)
2. CI/CD kimlikleri
3. İnsan kullanıcıları — burada grup kullanın, kişi değil
4. `owner` yalnızca break-glass için kalsın

## Grup kullanın

Rolü kişiye vermek, ekip değiştiğinde unutulur. Google Workspace grubuna verirseniz üyelik değişimi erişimi otomatik günceller:

```bash
gcloud projects add-iam-policy-binding sirket-uretim-web \
  --member="group:platform-ekibi@sirket.com" \
  --role="roles/compute.viewer"
```

## Doğrulama adımı

Daraltmadan bir hafta sonra Cloud Logging'de reddedilen çağrıları arayın:

```
protoPayload.status.code=7
```

Kod 7 `PERMISSION_DENIED` demektir. Çıkan kayıtlar ya gerçekten gereken bir izni kestiğinizi ya da bilmediğiniz bir otomasyonu bulduğunuzu gösterir. İkisi de değerli — ama fark etmeden bırakılırsa ikisi de olaydır.
