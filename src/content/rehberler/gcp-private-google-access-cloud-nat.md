---
baslik: "Private Google Access ve Cloud NAT: harici IP'leri kaldırmak"
ozet: "Her sanal makineye genel IP vermek hem masraf hem saldırı yüzeyi. İkisini de kaldırıp bağlantıyı sürdürmenin yolu."
konu: "google-cloud"
etiketler: ["ag", "guvenlik", "maliyet"]
yayin: 2026-07-14
sure: 9
---

Yeni bir sanal makine oluşturduğunuzda varsayılan olarak harici IP alır. Çoğu iş yükü için buna gerek yoktur; makinenin internete çıkması yeterlidir, internetten erişilebilir olması değil.

## Private Google Access

Google API'lerine (Cloud Storage, Logging, Artifact Registry) erişim, harici IP olmadan alt ağ düzeyinde açılır:

```bash
gcloud compute networks subnets update uretim-alt-ag \
  --region=europe-west3 --enable-private-ip-google-access
```

Bunu açmadan harici IP'yi kaldırırsanız makine günlük gönderemez ve paket deposuna erişemez — en sık yapılan sıra hatası budur.

## Cloud NAT

Genel internete (paket depoları, üçüncü taraf API) çıkış için:

```bash
gcloud compute routers create nat-router --network=uretim-vpc --region=europe-west3

gcloud compute routers nats create uretim-nat \
  --router=nat-router --region=europe-west3 \
  --nat-all-subnet-ip-ranges --auto-allocate-nat-external-ips \
  --enable-logging --log-filter=ERRORS_ONLY
```

`--log-filter=ERRORS_ONLY` önemlidir: tüm bağlantıları günlüğe yazmak Logging faturasını hızla şişirir.

## Harici IP'leri kaldırın

```bash
gcloud compute instances delete-access-config vm01 \
  --access-config-name="external-nat" --zone=europe-west3-a
```

Kuruluş politikasıyla yeni makinelerde harici IP'yi tamamen yasaklayabilirsiniz:

```bash
gcloud resource-manager org-policies enable-enforce \
  constraints/compute.vmExternalIpAccess --folder=987654321098
```

## Doğrulama adımı

Harici IP'yi kaldırdıktan sonra makinede üç testi de yapın: `gsutil ls gs://<kova>` (Private Google Access), `curl -I https://example.com` (Cloud NAT) ve dışarıdan makineye `ping` (**başarısız olmalı**). Üçüncüsü doğrulanmadan saldırı yüzeyini gerçekten kapattığınızı bilemezsiniz.
