---
baslik: "Google Cloud proje hiyerarşisi: kuruluş, klasör, proje"
ozet: "Politika ve fatura hiyerarşiden akar. Sonradan taşımak mümkün ama acı verir; ilk gün doğru kurmanın yolu."
konu: "google-cloud"
etiketler: ["yonetisim", "iam", "organizasyon"]
yayin: 2026-01-27
sure: 10
---

Google Cloud'da proje, kaynakların ve faturanın temel birimidir. "Her şeyi tek projede tutalım" kararı ilk altı ay rahat eder, sonrasında hem erişim hem maliyet ayrıştırılamaz hâle gelir.

## Sade bir ağaç

```
Kuruluş (sirket.com)
├── platform/
│   ├── ag-merkez        → paylaşılan VPC, Cloud NAT, DNS
│   ├── gunluk-arsiv     → log sink hedefi
│   └── guvenlik
├── is-yukleri/
│   ├── uretim
│   └── test
└── sanal-alan/          → 30 günlük denemeler
```

```bash
gcloud resource-manager folders create --display-name="is-yukleri" \
  --organization=123456789012

gcloud projects create sirket-uretim-web --folder=987654321098
```

## Neden klasör

Klasör olmadan politikayı ya tek projeye ya da tüm kuruluşa uygularsınız; ikisi de yanlış granülariteyi zorlar. Klasörle "üretimde harici IP yasak" kuralını yalnızca doğru dala yazarsınız.

```bash
gcloud resource-manager org-policies set-policy politika.yaml \
  --folder=987654321098
```

## Paylaşılan VPC

Ağı her projede ayrı kurmak, güvenlik duvarı kurallarını çoğaltır ve kimse hepsini denetleyemez. Paylaşılan VPC ile ağ tek bir ana projede durur, iş yükü projeleri onu kullanır:

```bash
gcloud compute shared-vpc enable sirket-ag-merkez
gcloud compute shared-vpc associated-projects add sirket-uretim-web \
  --host-project=sirket-ag-merkez
```

## Etiket değil, label ve tag

GCP'de iki ayrı kavram vardır: `labels` faturalama ve gruplama içindir; `tags` politika koşulları içindir. Maliyet raporu istiyorsanız `labels`, koşullu politika istiyorsanız `tags` kullanın. Karıştırmak yaygın bir zaman kaybıdır.

## Doğrulama adımı

Hiyerarşiyi kurduktan sonra bir test kısıtlamasını yalnızca `is-yukleri/uretim` klasörüne uygulayın ve `sanal-alan` içindeki bir projede aynı işlemi deneyin — **serbest olmalı**. İkisi de aynı davranıyorsa politika yanlış düzeye bağlanmıştır.
