---
baslik: "Azure abonelik hiyerarşisi: landing zone'a sıfırdan başlamak"
ozet: "Yönetim grubu ağacını yanlış kurarsanız politika ve maliyet raporları hep yanlış yerden akar. Küçük ortamlar için sade bir şablon."
konu: "azure"
etiketler: ["yonetisim", "landing-zone"]
yayin: 2026-06-09
sure: 12
---

Microsoft'un referans landing zone mimarisi büyük kurumlar için tasarlanmıştır ve 200 kullanıcılı bir şirkete olduğu gibi uygulanırsa yalnızca karmaşa üretir. Yine de temel fikir doğrudur: **politika ve maliyet, hiyerarşiden akar.**

## Sade bir ağaç

```
Kök yönetim grubu (kurulus)
├── platform
│   ├── kimlik          → domain controller'lar, Entra Connect
│   ├── yonetim         → Log Analytics, yedekleme kasası
│   └── baglanti        → hub sanal ağ, güvenlik duvarı, VPN ağ geçidi
├── is-yukleri
│   ├── uretim
│   └── test
└── sanal-alan          → denemeler, 30 günde silinir
```

Beş yönetim grubu, çoğu orta ölçekli şirket için yeterlidir. Daha fazlası, gerçek bir ihtiyaç doğmadan eklenmemelidir.

## Neden bu ağaç

- **Politika kalıtımı doğru yönde akar.** "Üretimde genel IP yasak" kuralını `uretim` altına koyarsınız; sanal alan etkilenmez.
- **Maliyet doğal olarak bölünür.** Cost Analysis'te yönetim grubuna göre gruplayınca platform maliyeti iş yükü maliyetinden ayrılır.
- **Erişim sadeleşir.** Ağ ekibi yalnızca `baglanti` üzerinde yetkilidir; üretime dokunamaz.

```bash
az account management-group create --name kurulus --display-name "Kuruluş"
az account management-group create --name platform --parent kurulus
az account management-group create --name is-yukleri --parent kurulus
az account management-group create --name uretim --parent is-yukleri
```

## Sanal alan aboneliği: en çok atlanan parça

Geliştiricilerin deneme yapacağı bir yer yoksa denemeleri üretimde yaparlar. Sanal alana bütçe uyarısı ve otomatik temizlik koyun; yasak koymayın.

## Doğrulama adımı

Hiyerarşiyi kurduktan sonra tek bir test politikası (`Audit` etkisiyle) `uretim` grubuna atayın ve `sanal-alan` altındaki bir kaynağın uyumluluk raporunda **görünmediğini** doğrulayın. Görünüyorsa abonelik yanlış dalda duruyordur — bunu ilk gün fark etmek, altı ay sonra fark etmekten çok ucuzdur.
