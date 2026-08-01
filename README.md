# bilgince

BT rehberleri ve saha ipuçları için kişisel blog + portfolyo. Astro 5, statik çıktı, sıfır istemci çatısı.

## Çalıştırma

```bash
npm install
npm run dev        # http://localhost:4321
npm run build      # dist/ üretir + Pagefind arama dizinini kurar
npm run preview    # derlenmiş çıktıyı yerel olarak sunar

npm run baglanti-kontrol   # dist/ içindeki kırık iç bağlantıları listeler (build sonrası)
```

Arama (Pagefind) yalnızca `npm run build` sonrası çalışır; `npm run dev` sırasında `/ara`
sayfası bunu belirten bir not gösterir.

## Sayfa haritası

| Adres | Dosya | Ne yapar |
| --- | --- | --- |
| `/` | `src/pages/index.astro` | Hero, güven şeridi, öne çıkanlar, günün ipucu, son rehberler, portfolyo, bülten |
| `/rehberler` | `src/pages/rehberler/index.astro` | Tüm rehberlerin arşivi |
| `/rehberler/<slug>` | `src/pages/rehberler/[...slug].astro` | Yazı detayı: içindekiler, okuma çubuğu, önceki/sonraki |
| `/rehberler/sayfa/<n>` | `src/pages/rehberler/sayfa/[sayfa].astro` | Arşivin 2. ve sonraki sayfaları (`SAYFA_BASI`, `src/site.js`) |
| `/konu/<slug>` | `src/pages/konu/[konu].astro` | Konu arşivi ve seri ilerlemesi |
| `/seri/<slug>` | `src/pages/seri/[seri].astro` | Serinin bölümleri sırayla, `ItemList` şemasıyla |
| `/etiket/<slug>` | `src/pages/etiket/[etiket].astro` | Etiketin geçtiği rehberler ve komutlar |
| `/ipuclari` | `src/pages/ipuclari/index.astro` | Hızlı ipuçları |
| `/komutlar` | `src/pages/komutlar.astro` | Komut kütüphanesi: konuya göre süzme, metin arama, kopyala düğmesi |
| `/ozgecmis/yazdir` | `src/pages/ozgecmis/yazdir.astro` | Yazdırma düzeni — tarayıcıdan "PDF olarak kaydet" |
| `/portfolyo` | `src/pages/portfolyo/index.astro` | Proje listesi |
| `/portfolyo/<slug>` | `src/pages/portfolyo/[...slug].astro` | Sorun → Yaklaşım → Sonuç, aşamalar, metrikler |
| `/hakkimda` | `src/pages/hakkimda.astro` | Anlatı, SSS, iletişim kanalları |
| `/ozgecmis` | `src/pages/ozgecmis.astro` | Zaman çizelgesi, yetenekler, sertifikalar, CV indirme |
| `/ara` | `src/pages/ara.astro` | Pagefind arayüzü |
| `/404` | `src/pages/404.astro` | Öneri bağlantılı hata sayfası |
| `/rss.xml` | `src/pages/rss.xml.ts` | RSS akışı |
| `/og/<slug>.png` | `src/pages/og/[...slug].png.ts` | 1200×630 paylaşım kartı (derleme sırasında üretilir) |

## İçerik ekleme

Markdown dosyaları `src/content/` altında. Şema `src/content.config.ts` içinde tanımlı;
zorunlu bir alanı unutursanız derleme hata verir — bu kasıtlı.

Yeni rehber: `src/content/rehberler/<slug>.md`

```yaml
---
baslik: "Başlık"
ozet: "Meta açıklama olarak da kullanılır — 155 karakteri geçmesin."
seoBaslik: "Arama için farklı başlık (isteğe bağlı)"
konu: "powershell"          # src/site.js içindeki KONULAR slug'larından biri
etiketler: ["etiket-1"]
yayin: 2026-08-01
guncelleme: 2026-08-10      # isteğe bağlı; "son güncelleme" rozetini besler
sure: 12                    # dakika
seri: "Sıfırdan Active Directory"   # isteğe bağlı
oneCikan: false             # ana sayfada baş yazı olsun mu
taslak: false               # true ise hiçbir yerde görünmez
---
```

Adres otomatik olarak dosya adından gelir: `pasif-ad-hesap-raporu.md` → `/rehberler/pasif-ad-hesap-raporu`.
Slug'ı değiştirmeyin — kalıcı bağlantı kırılır.

## Yer tutucular

Yayına almadan önce değiştirilmesi gerekenler:

- `src/site.js` — site adı, alan adı, ad-soyad, e-posta, sosyal hesaplar, bülten uç noktası
- `src/cv.js` — iş deneyimi, sertifikalar, SSS
- `public/robots.txt` — site haritası adresi
- `src/content/projeler/*.md` — proje metrikleri

**Şu anki kişisel içeriğin tamamı uydurmadır** — iş yerleri, tarihler, sertifikalar ve proje
sayıları gerçekçi görünsün diye yazıldı. Yayına almadan önce değiştirin.

## Bülten

`src/site.js` içindeki `newsletter.endpoint` boşken sayfalarda form yerine "sağlayıcı bağlanmadı"
notu görünür — kimse boşluğa abone olmaz. Sağlayıcının form uç noktasını yazdığınız anda form
etkinleşir; JavaScript varsa sayfadan ayrılmadan gönderir, yoksa normal form POST'u çalışır.

## Yayın

Statik çıktı, herhangi bir statik sunucuda çalışır.

- **Netlify** — `netlify.toml` hazır (`npm run build`, `dist`).
- **Cloudflare Pages** — derleme komutu `npm run build`, çıktı dizini `dist`.
- **GitHub Pages** — `src/site.js` içindeki `url` alanını `https://<kullanici>.github.io/<repo>`
  yapın ve `astro.config.mjs`'e `base: '/<repo>'` ekleyin; aksi hâlde bağlantılar ve OG adresleri kayar.

`public/_headers` uzun ömürlü önbellek ve temel güvenlik başlıklarını ayarlar (Netlify ve
Cloudflare Pages okur).

## SEO

Her sayfada `<title>`, meta description, canonical, Open Graph, Twitter card ve JSON-LD var:

- Yazılar → `TechArticle` + `BreadcrumbList`
- Konu ve arşiv sayfaları → `CollectionPage`
- Projeler → `CreativeWork`
- Hakkımda → `ProfilePage` + `Person` + `FAQPage`
- Özgeçmiş → `Person` (`hasCredential`, `hasOccupation`)

Paylaşım kartları derleme sırasında satori + sharp ile üretilir. Yazı tipi
`src/assets/fonts/` altındaki statik Nunito WOFF dosyalarından okunur (satori woff2 okuyamaz).

## Tasarım

Renk mantığı: lacivert gövde metni, indigo eylem rengi, lavanta zemin blokları.
Kehribar ve yeşil dekor değil — kehribar dikkat/ipucu, yeşil doğrulanmış sonuç bildirir.
Tüm belirteçler `src/styles/global.css` başındaki `:root` bloğunda.

Tipografi tek aile: Nunito değişken ağırlık (300–1000), woff2 olarak gömülü ve `preload`
ediliyor. Türkçe karakterler için latin-ext alt kümesi ayrıca yükleniyor.

Tasarım önerilerinin ilk hâli `mockup/tema-onerileri.html` içinde duruyor.
