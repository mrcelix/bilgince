---
baslik: "QoS: ses ve video için gerçek sınıflandırma"
ozet: "Trafiği işaretlemek yetmez; operatör işareti tanımıyorsa hiçbir şey değişmez. Şube çıkışında gerçekten işe yarayan kurulum."
konu: "sd-wan"
etiketler: ["qos", "ses", "operasyon"]
yayin: 2026-03-31
sure: 10
---

QoS ile ilgili en yaygın yanılgı, paketleri DSCP ile işaretlemenin tek başına bir şey değiştirdiğidir. İnternet devresinde operatör bu işareti çoğu zaman sıfırlar. QoS'un gerçekten çalıştığı yer **kendi çıkış kuyruğunuzdur**.

## Şube çıkışı: darboğaz sizsiniz

Şubenin 100 Mbps yükleme kapasitesi varsa ve bir yedekleme işi bunu doldurursa, ses paketleri kuyrukta bekler. Çıkış şekillendirmesini (shaping) devrenin biraz altına ayarlayın ki kuyruk sizin cihazınızda oluşsun ve önceliklendirmeyi siz yapın:

```
sekillendirme = devre_hizi × 0.90
```

Bu %10'luk fedakârlık, önceliklendirmenin çalışabilmesinin bedelidir.

## Dört sınıf yeter

Sekiz sınıflı tasarımlar kâğıtta güzeldir, sahada kimse bakımını yapamaz.

| Sınıf | İçerik | Davranış |
| --- | --- | --- |
| Gerçek zamanlı | Ses, video çağrısı | Katı öncelik, bant genişliği sınırlı |
| İş kritik | ERP, VDI, SaaS | Garantili pay |
| Varsayılan | Web, e-posta | Kalan kapasite |
| Toplu | Yedekleme, güncelleme | En düşük, iş saatinde sınırlı |

Gerçek zamanlı sınıfa **üst sınır koyun** (tipik olarak devrenin üçte biri). Sınır yoksa hatalı sınıflandırılmış tek bir akış tüm hattı katı öncelikle işgal edebilir.

## Sınıflandırma nerede yapılmalı

Kaynağa en yakın yerde. Uygulama zaten doğru DSCP ile işaretliyorsa güvenin; işaretlemiyorsa şube cihazında uygulama tanıma ile işaretleyin. Merkeze geldikten sonra sınıflandırmak geç kalmıştır.

## Doğrulama adımı

Yapılandırmadan sonra kasıtlı doygunluk üretin: şubeden büyük bir dosya yüklerken aynı anda bir ses çağrısı yapın. Çağrı kalitesi bozulmuyorsa QoS çalışıyordur. Ayrıca kuyruk sayaçlarına bakın — toplu sınıfta **düşen paket** görmelisiniz. Hiçbir sınıfta düşme yoksa şekillendirme devreden düşük değil, yüksek ayarlanmıştır ve kuyruk sizde değil operatördedir.
