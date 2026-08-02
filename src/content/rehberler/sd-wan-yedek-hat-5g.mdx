---
baslik: "Yedek hat olarak 4G/5G: devreye alma ve eşikler"
ozet: "Mobil yedek ucuz bir sigortadır ama yanlış kurulursa ya hiç devreye girmez ya da faturayı patlatır."
konu: "sd-wan"
etiketler: ["sube", "yedeklilik", "5g"]
yayin: 2026-03-10
sure: 9
---

Şubede tek devre varsa yedek hattın maliyeti, bir günlük kesintinin maliyetinin yanında önemsizdir. Ama mobil yedek üç noktada yanlış kurulur.

## 1. Sinyal seviyesi ölçülmeden anten yerleştirilmesi

Modem dolabın içinde, betonun arkasındaysa yedek hat kâğıt üzerinde vardır. Devreye almadan önce ölçün ve kaydedin:

```
RSRP  > -100 dBm   → iyi
RSRP  -100..-110   → sınırda, harici anten düşünün
RSRP  < -110 dBm   → yedek sayılmaz
```

Bu değerleri kurulum belgesine yazın; altı ay sonra "yedek neden yavaş" tartışmasını bitirir.

## 2. Yalnızca hat kopmasına bakan failover

Devre fiziksel olarak ayakta ama paket geçmiyorsa (operatör tarafında sorun) arayüz "up" görünür ve geçiş olmaz. Bu yüzden failover kararı arayüz durumuna değil, **uçtan uca sağlık kontrolüne** bağlanmalı: merkezdeki bir hedefe düzenli aralıklarla prob gönderilmeli.

## 3. Veri paketi kontrolsüz kullanılması

Yedek devreye girdiğinde tüm trafik oradan akar; yedekleme işi de dahil. Bir gecede aylık kotayı bitirebilir.

Yedek hattayken politikayı daraltın:
- Yedekleme, çoğaltma, yazılım dağıtımı → **durdurulsun**
- SaaS ve ses → geçsin
- Misafir ağı → kapatılsın

## Doğrulama adımı

Çeyrekte bir, planlı olarak birincil hattı kapatın ve şu üçünü ölçün: **geçiş süresi**, **yedek hat üzerindeki gerçek hız**, **o sırada oluşan veri tüketimi**. Üçüncüsü, gerçek bir kesintide faturanızın ne olacağını söyleyen tek sayıdır. Tatbikatı iş saatleri dışında yapın ama gerçekten yapın — hiç denenmemiş yedek hat, yedek hat değildir.
