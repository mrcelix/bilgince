---
baslik: "Öncelik matrisi: etki × aciliyet gerçekten nasıl kurulur"
ozet: "Herkesin kaydı 'yüksek' önceliklidir. Etki ve aciliyeti ölçülebilir tanımlara bağlamadan matris işe yaramaz."
konu: "itsm"
etiketler: ["oncelik", "sla", "surec"]
yayin: 2026-02-03
sure: 9
---

Öncelik matrisi her ITSM aracında hazır gelir ve neredeyse her kurumda işlevsizdir. Sebep matris değil, etki ve aciliyetin tanımsız bırakılmasıdır.

## Etkiyi sayıya bağlayın

"Yüksek etki" ifadesi kişiye göre değişir. Sayıya bağlayın:

| Etki | Tanım |
| --- | --- |
| Yüksek | Bir hizmetin tamamı durdu **veya** 50'den fazla kullanıcı etkilendi **veya** gelir/üretim durdu |
| Orta | Bir departman veya 10–50 kullanıcı etkilendi; geçici çözüm var |
| Düşük | Tek kullanıcı, geçici çözümle çalışmaya devam edebiliyor |

## Aciliyeti işe bağlayın

| Aciliyet | Tanım |
| --- | --- |
| Yüksek | Beklemek zararı büyütüyor (veri kaybı, yasal süre, üretim hattı) |
| Orta | İş yavaşlıyor ama devam ediyor |
| Düşük | Planlı bir tarihe kadar beklenebilir |

## Matris

|  | Aciliyet Y | Aciliyet O | Aciliyet D |
| --- | --- | --- | --- |
| **Etki Y** | P1 | P2 | P3 |
| **Etki O** | P2 | P3 | P4 |
| **Etki D** | P3 | P4 | P4 |

## P1'i korumak

P1, gerçekten her şeyin durduğu durumdur ve ayda bir–iki kez olmalıdır. Haftada üç P1 açılıyorsa ya tanım gevşektir ya da altyapıda ciddi bir problem vardır — ikisi de araştırılmalıdır.

Pratik bir kural: **P1 açma yetkisini herkese vermeyin.** Kullanıcı "çok acil" der; önceliği servis masası, tanıma bakarak belirler. Bu bir güven meselesi değil, tutarlılık meselesidir.

## Ölçüm

Üç ay boyunca **öncelik dağılımını** takip edin. Sağlıklı bir dağılımda kayıtların %60–70'i P3–P4'tür. P1–P2 payı %30'un üzerindeyse matris uygulanmıyordur; kimse öncelik sırasına güvenmiyor demektir.

İkinci sayı: **kapanışta önceliği değiştirilen kayıt oranı.** %15'in üzerindeyse tanımlarınız hâlâ yoruma açıktır.
