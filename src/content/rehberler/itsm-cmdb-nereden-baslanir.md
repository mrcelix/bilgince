---
baslik: "CMDB: nereden başlanır, ne kadar detay yeterli"
ozet: "Her vidayı kaydetmeye çalışan CMDB projeleri biter, kullanılmaz. Kapsamı iş sorusundan geriye doğru çizmek."
konu: "itsm"
etiketler: ["cmdb", "envanter", "surec"]
yayin: 2026-05-19
sure: 10
---

CMDB projelerinin çoğu "önce her şeyi envantere alalım" diye başlar ve on sekiz ay sonra kimsenin güvenmediği bir veritabanıyla biter. Doğru başlangıç tersidir: **hangi soruyu cevaplamak istiyoruz?**

## Üç soruyla başlayın

1. "Bu sunucu kapanırsa hangi hizmet etkilenir?"
2. "Bu hizmet için hangi bileşenler var ve sahibi kim?"
3. "Bu değişiklik neyi etkiler?"

Bu üç soruyu cevaplayabilen bir CMDB, tam envanterden çok daha değerlidir. Ve kapsamı çok daha küçüktür.

## Minimum veri modeli

| Yapılandırma öğesi | Zorunlu alanlar |
| --- | --- |
| Hizmet | Ad, sahip, kritiklik, bağlı olduğu bileşenler |
| Sunucu / sanal makine | Ad, ortam, işletim sistemi, sahip, bağlı hizmet |
| Uygulama | Ad, sürüm, sahip, çalıştığı sunucular |
| Veritabanı | Ad, örnek, sahip, yedekleme planı |

Dördü de var, ilişkiler kurulmuşsa üç soru cevaplanabilir. Ağ portu, kablo etiketi ve monitör seri numarası bu aşamada gerekmez.

## Otomatik keşif şart

Elle güncellenen CMDB üç ay içinde yanlış olur. Keşif aracı yoksa CMDB'ye başlamayın; önce keşfi çözün. Keşif verisi ile elle girilen veriyi de ayırın: sahiplik ve kritiklik insandan, teknik alanlar keşiften gelmeli.

## Kritikliği iş belirlesin

"Bu sunucu kritik mi?" sorusunu sistem yöneticisine sorarsanız cevap her zaman evettir. İş birimine sorun ve şu biçimde sorun: "Bu hizmet iki saat dursa ne olur?" Cevap somutsa kritiklik de somut olur.

## Ölçüm

İki sayı: **keşif kapsamı** (bilinen cihazların yüzde kaçı otomatik güncelleniyor) ve **sahipsiz kayıt oranı**. İkincisi %10'un üzerindeyse veri güvenilir değildir. Üçüncü ve en önemli ölçüm ise şudur: son üç ayda kaç olay veya değişiklik kaydında CMDB gerçekten kullanıldı? Sıfırsa proje teknik olarak başarılı, pratikte başarısızdır.
