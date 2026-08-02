---
baslik: "SD-WAN + SASE: güvenlik şubeden nereye taşınıyor?"
ozet: "Yerel çıkış açtığınız anda şube güvenlik duvarınız yetmez. Bulut tabanlı güvenlik katmanına geçerken sıra ve tuzaklar."
konu: "sd-wan"
etiketler: ["sase", "guvenlik", "mimari"]
yayin: 2026-04-21
sure: 11
---

SD-WAN'ın en büyük kazancı yerel çıkıştır: SaaS trafiği merkeze uğramadan doğrudan internete gider. Aynı hamle en büyük güvenlik boşluğunu da açar — o trafik artık merkezdeki güvenlik yığınından geçmiyordur.

## Üç seçenek

**1. Şubede tam yığın.** Her şubeye güvenlik duvarı, IPS, URL filtresi. Güvenli ama pahalı ve bakımı imkânsız.

**2. Trafiği merkeze geri çekmek (backhaul).** Güvenli, ama SD-WAN'ın kazancını iptal eder. M365 trafiğini merkeze çekmek, Microsoft'un kendi önerisine de aykırıdır.

**3. Bulut güvenlik katmanı (SASE/SSE).** Şube doğrudan çıkar ama trafiği bulut hizmetinden geçirir. Çoğu kurum için doğru cevap budur.

## Geçiş sırası

1. **Önce misafir ağı.** En düşük risk, en hızlı öğrenme.
2. **Sonra genel internet trafiği.** URL filtreleme ve TLS denetimi burada devreye girer.
3. **En son SaaS.** M365 gibi hizmetler için sağlayıcının önerdiği "bypass" listesini uygulayın; her paketi denetlemeye çalışmak performansı bozar.

## TLS denetiminin bedeli

TLS denetimi olmadan URL filtresi sadece alan adını görür. Denetim açıldığında ise sertifika sabitleme (certificate pinning) kullanan uygulamalar kırılır: bankacılık, bazı mobil uygulamalar, güncelleme servisleri. Bu yüzden istisna listesi kaçınılmazdır ve zamanla büyür — bunu bir başarısızlık değil, normal işletme yükü sayın.

## Kimlik, IP'nin yerini alır

SASE'nin asıl farkı budur: politika kaynağı IP adresi değil, **kullanıcı kimliği** olur. Bu da kimlik sağlayıcınızın (Entra ID, Okta) doğru gruplarla hazır olmasını gerektirir. Grup yapısı dağınıksa SASE projesi bir kimlik temizliği projesine dönüşür — ve bu, projenin en uzun kısmıdır.

## Doğrulama adımı

Devreye aldıktan sonra şubeden üç test: engellenen bir kategoriye erişmeyi deneyin (**engellenmeli**), M365'e erişin (**hızlı ve denetimsiz geçmeli**), bilinen bir zararlı yazılım test dosyasını (EICAR) indirmeyi deneyin (**engellenmeli**). Üçü de doğrulanmadan yerel çıkış üretime açılmamalı.
