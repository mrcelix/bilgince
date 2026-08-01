---
baslik: "Entra ID'ye kimlik göçü"
ozet: "400 kullanıcılık şirket içi Active Directory ortamının hibrit kimliğe taşınması; koşullu erişim ve çok faktörlü doğrulamanın tek bir kesinti yaşanmadan devreye alınması."
rol: "Proje sahibi"
sureMetni: "6 hafta"
yil: "2025–2026"
kapsam: "3 lokasyon"
sorun: "Şirket içi AD'de biriken 12 yıllık hesap kalabalığı, uzaktan çalışanlar için VPN bağımlılığı ve tek koruma katmanı olarak parola. Denetim raporunda MFA eksikliği kritik bulgu olarak işaretlendi."
yaklasim: "Önce temizlik, sonra göç. Pasif hesaplar ayıklandı, AD Connect ile hibrit kimlik kuruldu, koşullu erişim politikaları önce rapor modunda çalıştırıldı; yayım departman departman yapıldı."
sonuc: "Tüm kullanıcılar altı haftada hibrit kimliğe geçti. Tek bir planlı kesinti bile yaşanmadı; VPN kullanımı üçte iki azaldı ve denetim bulgusu kapandı."
teknolojiler: ["Entra ID", "AD Connect", "Intune", "PowerShell"]
metrikler:
  - { deger: "400", etiket: "Taşınan kullanıcı" }
  - { deger: "0", etiket: "Kesinti" }
  - { deger: "%92", etiket: "İlk hafta MFA kaydı" }
  - { deger: "-%66", etiket: "VPN kullanımı" }
asamalar:
  - baslik: "Envanter ve temizlik"
    aciklama: "400 hesabın 61'i 90 günden uzun süredir pasifti. Hizmet hesapları ayrıldı, İK listesiyle çapraz kontrol yapıldı, kalanlar karantina OU'suna alındı."
    zaman: "1.–2. hafta"
  - baslik: "AD Connect ve pilot grup"
    aciklama: "Eşitleme kuruldu, 20 kişilik BT ve finans pilot grubu taşındı. UPN uyumsuzlukları bu aşamada yakalandı — göçün en çok zaman yiyen kısmı burasıydı."
    zaman: "3. hafta"
  - baslik: "Koşullu erişim: rapor modu"
    aciklama: "Politikalar bir hafta boyunca yalnızca raporlama modunda çalıştırıldı. Bu sayede üç uygulamanın modern kimlik doğrulamayı desteklemediği, kimse dışarıda kalmadan görüldü."
    zaman: "4. hafta"
  - baslik: "Kademeli yayım ve break-glass"
    aciklama: "İki break-glass hesabı politikaların dışında bırakıldı ve fiziksel kasaya alındı. Yayım günde bir departman hızıyla tamamlandı."
    zaman: "5.–6. hafta"
ilgiliRehberler: ["entra-id-mfa-zorlama", "pasif-ad-hesap-raporu"]
sira: 1
---

Bu göçün en öğretici tarafı teknik kısmı değildi. Zor olan, 400 kişiye telefonlarına bir uygulama kurmalarını kabul ettirmekti.

İşe teknik ekipten değil, muhasebeden başladık: en çok direnç göstereceğini düşündüğümüz departman pilot oldu. İlk hafta üç kişiyle birebir oturduk, kaydı birlikte yaptık. O üç kişi departmanın geri kalanını ikna etti — bizim yazdığımız hiçbir kılavuz o kadar iş görmedi.

Teknik tarafta en büyük sürpriz UPN uyumsuzluğuydu: şirket içi AD'de `kullanici@sirket.local` olan hesapların bulutta yönlendirilebilir bir alan adına ihtiyacı vardı. Bunu eşitlemeden önce düzeltmek zorunludur; sonrasında düzeltmek her hesabı elle dokunmayı gerektirir.
