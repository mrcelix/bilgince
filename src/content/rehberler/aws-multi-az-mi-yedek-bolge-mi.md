---
baslik: "Multi-AZ mı yedek bölge mi? Dayanıklılığın gerçek fiyatı"
ozet: "İkisi farklı arızalara karşı korur ve maliyetleri çok farklıdır. RTO ve RPO'yu konuşmadan bu karar verilemez."
konu: "aws"
etiketler: ["sureklilik", "mimari", "maliyet"]
yayin: 2026-07-28
sure: 11
---

"Felaket kurtarma istiyoruz" cümlesi tek başına bir gereksinim değildir. İki soru cevaplanana kadar mimari çizilemez: **ne kadar veri kaybını göze alıyorsunuz (RPO)** ve **ne kadar sürede ayağa kalkmalısınız (RTO)**.

## Neye karşı koruyor?

**Multi-AZ**, tek bir veri merkezinin (availability zone) kaybına karşı korur. Aynı bölge içindedir, gecikme milisaniyelerdir, senkron çoğaltma mümkündür. Bölgesel bir kesintide işe yaramaz.

**Yedek bölge (multi-region)**, tüm bölgenin kaybına ve bölgesel hizmet arızalarına karşı korur. Gecikme yüzlerce milisaniyedir; senkron çoğaltma çoğu iş yükü için uygun değildir.

## Dört seçenek, artan maliyetle

| Yaklaşım | RPO | RTO | Göreli maliyet |
| --- | --- | --- | --- |
| Yalnızca yedek (backup & restore) | Saatler | Saatler–gün | En düşük |
| Pilot light | Dakikalar | Saatler | Düşük |
| Warm standby | Saniyeler–dakikalar | Dakikalar | Orta |
| Aktif–aktif | ~0 | ~0 | En yüksek |

Çoğu orta ölçekli şirket için doğru cevap **Multi-AZ + başka bölgede yedek kopya**dır. Aktif–aktif, maliyeti ve karmaşıklığı çoğu zaman gereksiz biçimde yükseltir.

## Sık atlanan bağımlılıklar

Yedek bölgeye veri kopyalamak yetmez. Şunlar da orada olmalı: AMI'ler, gizli anahtarlar (Secrets Manager çoğaltması), Route 53 kayıtları, sertifikalar ve **IAM rolleri**. Tatbikatta en sık takılınan yer sertifikalardır.

## Doğrulama adımı

Yılda bir kez tatbikat yapın ve saati tutun. Tatbikatta iki şeyi yazın: **gerçekleşen RTO** ve **eksik çıkan bağımlılıkların listesi**. Taahhüt ettiğiniz RTO ile ölçülen RTO arasındaki fark, mimarinizin gerçek durumudur — belge değil, kronometre söyler.
