---
baslik: "Uygulama farkında yol seçimini yapılandırmak"
ozet: "Trafiği IP'ye göre değil uygulamaya göre yönlendirmek. Eşikler, ölçüm penceresi ve geri dönme (flapping) sorunu."
konu: "sd-wan"
etiketler: ["yol-secimi", "qos", "operasyon"]
yayin: 2026-02-17
sure: 12
---

SD-WAN'ın asıl değeri şuradadır: aynı anda iki hat varken, hangi trafiğin hangi hattan gideceğine **uygulama bazında** karar verebilmek.

## Politika sırası

Politikalar yukarıdan aşağı değerlendirilir; ilk eşleşen kazanır. Bu yüzden en özel kural en üstte olmalı:

```
1. Ses/video (SIP, RTP, Teams)   → düşük jitter hattı, yedek: MPLS
2. VDI / uzak masaüstü            → düşük gecikme hattı
3. SaaS (M365, Salesforce)        → yerel çıkış, en iyi internet hattı
4. Yedekleme/çoğaltma             → yalnızca ucuz hat, iş saatlerinde sınırlı
5. Geri kalan her şey             → yük dengeli
```

Dördüncü kural en çok fayda üretenidir: yedekleme trafiği pahalı hattı iş saatinde doldurmasın.

## Eşikler

Ses için tipik başlangıç eşikleri:

```
gecikme    < 150 ms
jitter     < 30 ms
paket kaybı< %1
```

Eşiği aşan hat, o uygulama sınıfı için devre dışı bırakılır — hattın tamamı kapanmaz, yalnızca o sınıf diğer hatta taşınır.

## Flapping'i önleyin

Eşiğe yakın seyreden bir hat, saniyede bir yol değiştirebilir. Bu, sorunun kendisinden daha kötüdür: her geçişte oturumlar kırılır.

İki ayar bunu keser: **ölçüm penceresini uzatın** (tek örnek yerine 10 örneğin ortalaması) ve **geri dönüş için histerezis** koyun (hat, eşiğin belirgin altına inip orada bir süre kalmadan geri alınmasın).

## Doğrulama adımı

Yapılandırmadan sonra bir hatta kasıtlı bozulma üretin — laboratuvarda gecikme ekleyin ya da hattı fiziksel olarak kesin. İki şeyi ölçün: **kaç saniyede geçiş yapıldı** ve **aktif ses çağrısı düştü mü**. Çağrı düşüyorsa geçiş süresi çok uzundur; sürekli geçiş oluyorsa histerezis yetersizdir. İkisi de ölçülmeden politika üretime alınmamalı.
