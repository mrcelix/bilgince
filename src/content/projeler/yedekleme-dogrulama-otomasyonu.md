---
baslik: "Yedekleme doğrulama otomasyonu"
ozet: "Aylık geri dönüş testini otomatikleştiren PowerShell çatısı: izole ortamda açılış, servis kontrolü ve raporun e-postayla dağıtımı."
rol: "Tasarım ve uygulama"
sureMetni: "3 hafta"
yil: "2024"
kapsam: "42 sanal makine"
sorun: "Yedekler her gece alınıyordu ama son gerçek geri dönüş testi 14 ay öncesindeydi. Yedeğin çalıştığını kimse kanıtlayamıyordu."
yaklasim: "Ayda bir, rastgele seçilen üç sanal makine izole bir ağ segmentinde otomatik olarak geri yüklendi; açılış, servis durumu ve veritabanı bağlantısı kontrol edildi."
sonuc: "Doğrulama artık insan hatasına bağlı değil. İlk çalıştırmada iki yedeğin bozuk olduğu ortaya çıktı — bunlar 14 aydır bozuktu."
teknolojiler: ["PowerShell", "Veeam API", "Hyper-V"]
metrikler:
  - { deger: "%100", etiket: "Aylık doğrulama" }
  - { deger: "14 sa", etiket: "Aylık el emeği tasarrufu" }
  - { deger: "2", etiket: "Bulunan bozuk yedek" }
asamalar:
  - baslik: "İzole test ağı"
    aciklama: "Üretim ağından tamamen ayrık bir VLAN ve ayrı bir Hyper-V host'u kuruldu; geri yüklenen makineler üretimle asla konuşmuyor."
    zaman: "1. hafta"
  - baslik: "Geri yükleme ve kontrol betiği"
    aciklama: "Veeam API üzerinden rastgele üç iş seçiliyor, izole ortama geri yükleniyor, açılış ve servis kontrolleri çalıştırılıyor."
    zaman: "2. hafta"
  - baslik: "Rapor ve temizlik"
    aciklama: "Sonuçlar HTML rapor olarak e-postayla gidiyor, test makineleri otomatik siliniyor. Başarısız test uyarı üretiyor."
    zaman: "3. hafta"
ilgiliRehberler: ["gpo-yedek-otomasyonu"]
sira: 2
---

Bu projeye başlarken varsayım şuydu: yedekler çalışıyor, sadece kanıtlayamıyoruz. İlk otomatik çalıştırma bu varsayımı bozdu — iki iş uzun süredir sessizce başarısız oluyordu ve günlükte "başarılı" görünüyordu, çünkü yedek alınmıştı ama içerik tutarsızdı.

Buradan çıkardığım şey basit: **yedeğin varlığı yedek değildir, geri dönüşü yedektir.**
