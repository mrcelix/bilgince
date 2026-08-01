---
baslik: "SD-WAN'da DNS ve yerel çıkış: yavaşlığın sessiz sebebi"
ozet: "Yerel çıkış açıldı ama DNS hâlâ merkezden çözülüyorsa kullanıcı en yakın sunucu yerine yanlış kıtaya gider."
konu: "sd-wan"
etiketler: ["dns", "yerel-cikis", "performans"]
yayin: 2026-06-23
sure: 9
---

Yerel çıkışı açtınız, SaaS trafiği artık merkeze uğramıyor — ama kullanıcılar hâlâ yavaşlıktan şikâyet ediyor. Sebep neredeyse her zaman DNS'tir.

## Sorun nasıl oluşuyor

CDN'ler ve büyük SaaS sağlayıcıları, size **DNS sorgusunun geldiği yere göre** en yakın sunucuyu döner. Şube doğrudan internete çıkıyor ama DNS sorgusu merkezdeki sunucuya gidiyorsa, sağlayıcı sizi merkezin yakınındaki sunucuya yönlendirir. Trafik yerel çıkıştan gider ama yanlış hedefe.

## Doğrulama

Şubeden ve merkezden aynı ismi çözün, dönen adresleri karşılaştırın:

```bash
# şubede
nslookup outlook.office365.com
# merkezde
nslookup outlook.office365.com
```

Aynı IP dönüyorsa DNS merkezden çözülüyordur ve yerel çıkışın faydası yarıya inmiştir.

## Çözüm sırası

1. Şube için **yerel DNS ilet** (forwarder) tanımlayın: iç alan adları merkeze, geri kalanı yerel çözümleyiciye.
2. Yerel çözümleyici olarak operatörün DNS'i yerine bilinen bir genel çözümleyici kullanmak çoğu zaman daha tutarlıdır — ama coğrafi doğruluk için EDNS Client Subnet desteğine bakın.
3. Bulut güvenlik katmanı (SASE) kullanıyorsanız DNS'i onun üzerinden çözün; hem filtreleme hem coğrafi doğruluk sağlanır.

## Bölünmüş ufuk (split-horizon) tuzağı

İç kaynaklar için iç DNS'e, dış kaynaklar için yerel çözümleyiciye gitmelisiniz. Ayrımı yanlış kurarsanız iç sunucu adları internete sızar ya da iç uygulamalara erişim kopar. Şube yönlendirme kurallarını iç alan adlarına göre açıkça yazın.

## Doğrulama adımı

Yapılandırmadan sonra şubede iki testi yapın: bir iç sunucu adını çözün (**iç IP dönmeli**) ve bir CDN adresini çözün (**şubeye coğrafi olarak yakın bir IP dönmeli**). İkincisini doğrulamak için dönen IP'nin bulunduğu bölgeye bakın; hâlâ merkez bölgesi görünüyorsa iş bitmemiştir.
