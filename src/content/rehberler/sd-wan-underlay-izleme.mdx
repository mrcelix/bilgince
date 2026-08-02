---
baslik: "Underlay izleme: operatörle tartışmayı veriyle bitirmek"
ozet: "Kullanıcı 'internet yavaş' dediğinde elinizde ölçüm yoksa haklı olan operatördür. Jitter, gecikme ve kayıp ölçümünü kurmak."
konu: "sd-wan"
etiketler: ["izleme", "operator", "tanilama"]
yayin: 2026-05-12
sure: 10
---

SD-WAN kontrolcüsü size overlay'in sağlığını gösterir. Sorun genelde altta, operatörün devresindedir — ve o veriyi kendiniz toplamazsanız kimse size vermez.

## Neyi ölçmeli

Üç metrik yeterlidir, ama **yüzdelik** olarak:

| Metrik | Eşik (iş saatleri) | Neden |
| --- | --- | --- |
| Gecikme (p95) | < 60 ms yurt içi | Kullanıcı algısı |
| Jitter (p95) | < 30 ms | Ses kalitesi |
| Paket kaybı (p95) | < %0,5 | TCP verimi |

Ortalama gecikmenin 20 ms olması, p95'in 300 ms olduğu gerçeğini gizler. Şikâyetler p95 anında gelir.

## Ölçümü nereye koymalı

Hem şube cihazında hem bağımsız bir noktada. Yalnızca SD-WAN cihazının kendi ölçümüne dayanırsanız operatör "bizim tarafta sorun görünmüyor" der ve tartışma orada biter. Bağımsız bir prob (şubedeki küçük bir cihaz veya sunucu) elinizi güçlendirir.

```bash
# basit ama işe yarar: sürekli ölçüm ve kayıt
mtr --report --report-cycles 100 --json 8.8.8.8 >> /var/log/mtr-$(date +%F).json
```

## Arıza kaydı açarken

Operatöre gidiş şu üç şeyi içermeli: **zaman damgalı ölçüm**, **devre numarası**, **etkilenen kullanıcı sayısı ve iş etkisi**. Bu üçü olmadan açılan kayıt, birinci seviye destekte döner durur.

## Yol değişimlerini izleyin

Ani gecikme artışlarının önemli bir kısmı operatörün yol değiştirmesinden gelir. Traceroute geçmişini saklarsanız "önce şu yoldan gidiyordu, dünden beri şuradan" diyebilirsiniz — bu cümle arıza kaydını hızlandıran tek cümledir.

## Doğrulama adımı

Ölçüm kurulduktan bir ay sonra, kullanıcıdan gelen bir "yavaşlık" şikâyetini alın ve o saatin verisine bakın. Eşikler aşılmamışsa sorun ağda değildir — uygulamaya bakın. Bu ayrımı yapabiliyor olmak, izleme yatırımının tek gerçek getirisidir.
