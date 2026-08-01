---
baslik: "Şube devreye alma: sıfır dokunuşla kurulum (ZTP)"
ozet: "Kutudan çıkan cihazı teknisyen olmadan ayağa kaldırmak. Şablon disiplini, ön koşullar ve saha gerçekleri."
konu: "sd-wan"
etiketler: ["ztp", "sube", "operasyon"]
yayin: 2026-01-27
sure: 10
---

Sıfır dokunuş kurulum, sahaya mühendis göndermeden şube açmayı vaat eder. Vaat gerçektir ama üç ön koşula bağlıdır ve saha bunları çoğu zaman sağlamaz.

## Üç ön koşul

1. **Cihaz, üreticinin devreye alma bulutunda kayıtlı olmalı.** Seri numarası ile kuruluma bağlanır. İkinci el veya başka bir kurumdan gelen cihazlarda bu kayıt temizlenmemiş olabilir.
2. **WAN arayüzü DHCP ile adres alabilmeli.** Operatör statik IP veriyorsa sıfır dokunuş bozulur; ya bir ön yapılandırma dosyası ya da tek seferlik konsol erişimi gerekir.
3. **DNS ve giden 443 açık olmalı.** Bazı operatörler yeni devrelerde varsayılan olarak filtre uygular.

## Şablon disiplini

Şubeleri tek tek yapılandırırsanız ZTP'nin anlamı kalmaz. Değişkenleri şablondan ayırın:

```yaml
# sube-sablonu.yaml
sube_kimlik: "{{ sube_kodu }}"
wan1: { arayuz: ge0/0, mod: dhcp, rol: birincil }
wan2: { arayuz: ge0/1, mod: lte, rol: yedek }
lan: { vlan: 10, ag: "10.{{ sube_no }}.0.0/24" }
qos_profili: standart-sube
```

Şube başına değişen yalnızca üç değer olmalı: kod, numara ve varsa yerel istisna. Dördüncü bir değişken eklemek istediğinizde durun ve bunun gerçekten şubeye özel mi yoksa yeni bir profil mi olduğunu sorun.

## Sahayla anlaşma

Kurulumu yapan kişi teknisyen değil, şube çalışanıdır. Ona verilecek talimat tek sayfa olmalı: hangi kablo nereye, hangi ışık ne anlama geliyor, kim aranacak. Bu sayfa hazır değilse ZTP saha ziyaretine döner.

## Doğrulama adımı

Cihaz bağlandıktan sonra merkezden üç kontrol: **kontrol düzlemi bağlantısı kurulu mu**, **her iki WAN da yukarıda mı**, **yedek hat üzerinden test tüneli kuruluyor mu**. Üçüncüsü en çok atlanandır — yedek hattı ilk kez gerçek kesintide denemek, yedek hattın olmaması demektir.
