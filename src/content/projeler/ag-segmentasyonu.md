---
baslik: "Ağ segmentasyonu ve VLAN yeniden yapılandırma"
ozet: "Düz ağ topolojisinin üretim, ofis ve misafir olarak ayrılması; güvenlik duvarı kural setinin sıfırdan yazılması ve belgelenmesi."
rol: "Planlama ve saha uygulaması"
sureMetni: "5 hafta"
yil: "2023"
kapsam: "3 lokasyon, 380 uç nokta"
sorun: "Tüm cihazlar tek bir düz ağdaydı: sunucular, kullanıcı bilgisayarları, kameralar ve misafir telefonları aynı yayın alanını paylaşıyordu. Tek bir bulaşma tüm ağa yayılabilirdi."
yaklasim: "Önce envanter ve trafik gözlemi, sonra kademeli VLAN ayrımı. Güvenlik duvarı kuralları varsayılan reddet üzerine kuruldu ve her kural gerekçesiyle birlikte belgelendi."
sonuc: "Yayın trafiği belirgin şekilde düştü, ağ kaynaklı destek çağrıları %40 azaldı. Kural setinin tamamı artık gerekçeli ve okunabilir."
teknolojiler: ["FortiGate", "VLAN", "802.1X"]
metrikler:
  - { deger: "-%40", etiket: "Ağ kaynaklı çağrı" }
  - { deger: "3", etiket: "Lokasyon" }
  - { deger: "0", etiket: "Planlanmamış kesinti" }
asamalar:
  - baslik: "Envanter ve trafik gözlemi"
    aciklama: "İki hafta boyunca hangi cihazın kiminle konuştuğu kaydedildi. Segmentasyon planı tahmine değil bu kayda dayandı."
    zaman: "1.–2. hafta"
  - baslik: "VLAN ayrımı"
    aciklama: "Misafir ağı önce ayrıldı — en düşük riskli adım. Ardından kameralar, en son sunucular."
    zaman: "3.–4. hafta"
  - baslik: "Varsayılan reddet ve belgeleme"
    aciklama: "Kural seti sıfırdan yazıldı; her kuralın yanına neden var olduğu ve kimin talep ettiği not edildi."
    zaman: "5. hafta"
ilgiliRehberler: []
sira: 3
---

Segmentasyonun teknik kısmı bir haftada biter. Zor olan, hangi cihazın kiminle konuşması gerektiğini bilmektir — ve bunu kimse bilmiyordu.

Bu yüzden iki haftayı yalnızca dinleyerek geçirdik. Elde ettiğimiz trafik haritası, projenin en değerli çıktısı oldu; kural setinden çok daha uzun ömürlü.
