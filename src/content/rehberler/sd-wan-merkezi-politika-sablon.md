---
baslik: "Merkezî politika yönetimi ve şablon disiplini"
ozet: "Yüz şubeyi tek tek yapılandırmak yönetilemez. Şablon, profil ve istisna ayrımını doğru kurmanın yolu."
konu: "sd-wan"
etiketler: ["operasyon", "sablon", "sube"]
yayin: 2026-06-02
sure: 9
---

SD-WAN'ın işletme kazancı merkezî yönetimden gelir. Ama şablon disiplini kurulmazsa altı ay içinde "merkezî yönetilen yüz farklı yapılandırma" ortaya çıkar.

## Üç katman

1. **Genel şablon** — tüm şubelerde aynı: NTP, DNS, günlük hedefi, kimlik doğrulama, temel güvenlik.
2. **Profil** — şube tipine göre: küçük ofis, çağrı merkezi, depo. Farklı QoS, farklı yedeklilik.
3. **Değişken** — şubeye özel: kod, IP bloğu, WAN parametreleri.

Kural şudur: **istisna, dördüncü bir katman değildir.** Bir şubeye özel ayar gerekiyorsa ya yeni bir profil doğmuştur ya da o ayar yanlıştır.

## Değişiklikleri sürümleyin

Yapılandırmayı kontrolcüde tutmak yeterli değildir. Şablonları bir depoda tutup değişiklikleri kayıt altına alın:

```bash
git log --oneline -- sablonlar/sube-standart.yaml
```

"Bu kural neden var" sorusunun cevabı, altı ay sonra yalnızca commit mesajında bulunur.

## Dağıtım sırası

Asla hepsine birden uygulamayın:

1. Laboratuvar şubesi (varsa) veya en küçük şube
2. Tek bir gerçek şube, 24 saat gözlem
3. Bir grup (5–10 şube)
4. Kalanlar

Her adımda geri alma planı hazır olmalı ve geri almanın ne kadar sürdüğü ölçülmüş olmalı.

## Bakım penceresi ve değişiklik kaydı

Merkezî yapılandırma değişikliği, bir düğmeye basmak kadar kolaydır — bu yüzden değişiklik yönetimi burada daha da önemlidir. Kolay olan işlem, kayıtsız yapılan işlem hâline gelir.

## Doğrulama adımı

Dağıtımdan sonra şablon uyumunu ölçün: kontrolcüde "şablondan sapmış" (out of sync / non-compliant) şube sayısını raporlayın. Bu sayı sıfır değilse birileri cihaza doğrudan bağlanıp elle değişiklik yapıyordur. O şubeleri tek tek düzeltmek yerine, doğrudan erişimi kısıtlayın — kaynağı kapatmadan sapma tekrar eder.
