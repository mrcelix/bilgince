---
baslik: "EC2 mi Fargate mi? Karar için beş soru"
ozet: "Sunucusuz her zaman ucuz değildir. İş yükünün şeklini ölçüp karar vermenin pratik yolu."
konu: "aws"
etiketler: ["ec2", "fargate", "maliyet"]
yayin: 2026-06-16
sure: 9
---

"Fargate daha modern" bir karar gerekçesi değildir. Karar, iş yükünün şekline bakılarak verilir.

## Beş soru

**1. Yük sürekli mi, dalgalı mı?**
7/24 sabit yükte EC2 (özellikle Savings Plan ile) genelde daha ucuzdur. Günün belli saatlerinde çalışan iş yükünde Fargate kazanır çünkü boşta duran kapasiteye ödeme yapmazsınız.

**2. Ölçek sıçraması ne kadar hızlı?**
Fargate görevleri saniyeler içinde başlar; EC2 Auto Scaling dakikalar. Ani yük artışlarında bu fark doğrudan kullanıcıya yansır.

**3. İşletim sistemine erişmeniz gerekiyor mu?**
Ajan kurmak, çekirdek parametresi değiştirmek, GPU sürücüsü yönetmek gerekiyorsa Fargate uygun değildir.

**4. Yama sorumluluğunu kim taşısın?**
EC2'de ana makine yamaları sizindir. Fargate'te değildir. Küçük ekiplerde bu kalem, fiyat farkından daha değerli olabilir.

**5. Depolama nasıl?**
Fargate'te kalıcı yerel disk yoktur; EFS bağlarsınız. Yoğun disk G/Ç varsa bu bir maliyet ve gecikme kalemi olur.

## Kaba hesap

```bash
# Fargate: vCPU-saat ve GB-saat üzerinden
# 0.5 vCPU / 1 GB, günde 8 saat, 30 gün:
#   vCPU: 0.5 × 8 × 30 = 120 vCPU-saat
#   Bellek: 1 × 8 × 30 = 240 GB-saat
```

Aynı iş yükü 7/24 çalışsaydı vCPU-saat 360'a çıkardı — kırılma noktası genelde buralarda olur. Kendi bölgenizin güncel birim fiyatlarıyla bu tabloyu bir kez kurun; her tartışmada işinize yarar.

## Doğrulama adımı

Karar verdikten sonra ilk ay Cost Explorer'da iş yükünü etiketiyle süzüp gerçek maliyeti tahminle karşılaştırın. Sapma %25'ten büyükse varsayımınız (genellikle çalışma süresi ya da bellek boyutu) yanlıştı — kararı değil, varsayımı düzeltin.
