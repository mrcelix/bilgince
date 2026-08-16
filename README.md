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

**Komut paleti:** her sayfada `Ctrl/⌘ + K` (ya da bir yazı alanında değilken `/`) hızlı
aramayı açar. Kutu boşken bölüm kısayolları ve popüler aramalar; yazmaya başlayınca aynı
Pagefind dizininde arayıp sonuçları kategorilere ayırır. Ok tuşlarıyla gezilir, `↵` açar,
`esc` kapatır. Bileşen `src/components/Palet.astro`, stili `global.css` sonunda.

Palet betiği bilerek `define:vars` kullanmıyor: o yöntem betiği paketlemenin dışında
bırakıp aynı 9 KB'ı 468 sayfaya satır içi kopyalıyordu. Veriyi kendi içe aktarımıyla
alıyor, sonuç tek ve önbelleklenen bir dosya. Stil de aynı nedenle bileşen içinde değil.

`/ara` sonuçları **kategoriye göre gruplar**: Rehber, Hızlı Çözüm, İpucu, Komut, Araç,
Portfolyo, Sayfa. Kategori `Base.astro`'ya geçilen `kategori` özelliğinden gelir ve
Pagefind'e hem süzgeç hem meta olarak yazılır. Arşiv, konu, etiket ve sayfalama sayfaları
`aramaya={false}` ile dizinin dışında tutulur — içerikleri zaten kaynak sayfalarda geçiyor.

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
| `/hizli-cozumler` | `src/pages/hizli-cozumler/index.astro` | Belirtiye göre arama; her kayıt indirilebilir bir araca çıkar |
| `/araclar` | `src/pages/araclar/index.astro` | Üreteçler ve indirilebilir betiklerin dizini (`src/araclar.js`) |
| `/araclar/parola` | `src/pages/araclar/parola.astro` | Parola ve geçiş cümlesi üreteci, entropi ölçümü |
| `/araclar/sizinti-kontrol` | `src/pages/araclar/sizinti-kontrol.astro` | Pwned Passwords k-anonimlik sorgusu, çevrimdışı örüntü analizi |
| `/araclar/wifi-qr` | `src/pages/araclar/wifi-qr.astro` | Wi-Fi QR kodu ve yazdırılabilir misafir kartı |
| `/araclar/paylasim-karti` | `src/pages/araclar/paylasim-karti.astro` | Site temasından sosyal medya görseli üretir |
| `/ozgecmis/yazdir` | `src/pages/ozgecmis/yazdir.astro` | Yazdırma düzeni — tarayıcıdan "PDF olarak kaydet" |
| `/portfolyo` | `src/pages/portfolyo/index.astro` | Proje listesi |
| `/portfolyo/<slug>` | `src/pages/portfolyo/[...slug].astro` | Sorun → Yaklaşım → Sonuç, aşamalar, metrikler |
| `/hakkimda` | `src/pages/hakkimda.astro` | Anlatı, SSS, iletişim kanalları |
| `/ozgecmis` | `src/pages/ozgecmis.astro` | Zaman çizelgesi, yetenekler, sertifikalar, CV indirme |
| `/ara` | `src/pages/ara.astro` | Pagefind arayüzü |
| `/404` | `src/pages/404.astro` | Öneri bağlantılı hata sayfası |
| `/rss.xml` | `src/pages/rss.xml.ts` | RSS akışı |
| `/og/<slug>.png` | `src/pages/og/[...slug].png.ts` | 1200×630 paylaşım kartı (derleme sırasında üretilir) |

## Yönetim paneli

`/admin` adresinde, **Google ile giriş**. İçerik koleksiyonları, menü/grup
tanımları, konular, araç kütüğü ve site ayarları buradan yönetilir; her kayıt
depodaki bir dosyaya yazılır.

| Ekran | Ne yönetir |
| --- | --- |
| `/admin` | Gösterge: sayaçlar, kurulum durumu, yayındaki derleme |
| `/admin/icerik/<koleksiyon>` | Rehber, ipucu, komut, çözüm, proje listesi ve düzenleme |
| `/admin/duzenle` | Tek kayıt: hızlı alanlar + ham frontmatter + gövde |
| `/admin/veri` | `ayarlar.json`, `menu.json`, `araclar.json`, `konu/*.json` + yeni konu |

**Yerelde** kimlik doğrulaması istemez ve doğrudan diske yazar:

```bash
npm run dev
```

Sonra `http://localhost:4321/admin`. Değişiklikler çalışma kopyanızda oluşur;
commit ve push sizde.

**Canlıda** iki şey gerekir: Google girişi ve depoya yazma jetonu. İkisi de
yoksa panel açılmaz — bu kasıtlı.

### 1. Google OAuth istemcisi

1. [console.cloud.google.com](https://console.cloud.google.com) → bir proje seçin ya da oluşturun.
2. **APIs & Services → OAuth consent screen**: tür *External*, uygulama adı
   `bilgince yönetim`, destek e-postası olarak kendi adresinizi girin. Uygulamayı
   *Testing* durumunda bırakabilirsiniz; o hâlde kendinizi **Test users** listesine ekleyin.
3. **Credentials → Create credentials → OAuth client ID → Web application**:
   - *Authorized JavaScript origins*: `https://bilgince.com`
   - *Authorized redirect URIs*: `https://bilgince.com/api/admin/google-donus`
     (yerelde de denemek isterseniz `http://localhost:4321/api/admin/google-donus` ekleyin)
4. Çıkan **Client ID** ve **Client secret** değerlerini saklayın.

### 2. Depoya yazma jetonu

GitHub → **Settings → Developer settings → Fine-grained tokens**: yalnızca
`mrcelix/bilgince` deposuna, **Contents: Read and write** izniyle bir jeton üretin.
Panel her kaydı bu jetonla commit'ler; commit mesajında düzenleyen e-posta yazar.

### 3. Vercel ortam değişkenleri

**Settings → Environment Variables** altına:

| Değişken | Değer |
| --- | --- |
| `GOOGLE_ISTEMCI_ID` | Google'ın verdiği Client ID |
| `GOOGLE_ISTEMCI_SIR` | Google'ın verdiği Client secret |
| `OTURUM_ANAHTARI` | Rastgele uzun bir dize — çerez imzası bununla üretilir |
| `ADMIN_EPOSTALAR` | `mcelik@gmail.com` (virgülle birden çok yazılabilir) |
| `GITHUB_JETON` | 2. adımdaki jeton |
| `GITHUB_DEPO` | İsteğe bağlı, varsayılan `mrcelix/bilgince` |
| `GITHUB_DAL` | İsteğe bağlı, varsayılan `main` |
| `KV_REST_API_URL` | Yorumlar için; Upstash/Vercel KV bağlanınca kendiliğinden gelir |
| `KV_REST_API_TOKEN` | Aynı |

Oturum anahtarını üretmek için:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

Sonra yeniden dağıtın. `/admin` açıldığında gösterge panelindeki **Kurulum
durumu** kutuları hangi parçanın eksik olduğunu söyler.

### Yorumlar

Yazı ve çözüm sayfalarının altındaki yorum bölümü. Yorumlar **onaydan sonra**
yayımlanır; onay ve yanıt `/admin/yorumlar` ekranından yapılır.

Depo olarak bir Upstash Redis (Vercel KV) veritabanı kullanılıyor — sitedeki tek
çalışma zamanı verisi bu. Kurulumu:

1. Vercel projesinde **Storage → Create Database → Upstash Redis** (ücretsiz katman yeterli).
2. Veritabanını projeye bağlayın; Vercel `KV_REST_API_URL` ve `KV_REST_API_TOKEN`
   değişkenlerini kendisi ekler. Upstash'i doğrudan kullanıyorsanız
   `UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN` adları da tanınır.
3. Yeniden dağıtın.

Değişkenler tanımlı değilken **yorum bölümü sitede hiç görünmez** — yarım çalışan
bir form göstermek yerine bölüm tamamen gizlenir. Gösterge panelindeki "Yorumlar"
kutusu durumu söyler.

Spam ve kötüye kullanıma karşı: gizli tuzak alan, form açılışından itibaren en az
üç saniye, on dakikada en fazla üç gönderim (IP'nin tuzlanmış özetine göre),
en fazla iki bağlantı, uzunluk sınırları. Yorum metni HTML olarak değil **düz
metin** olarak basılır.

Saklanan veri: ad, yorum, tarih, sayfa yolu, isteğe bağlı e-posta (yalnızca
panelde görünür, sitede asla) ve IP'nin tuzlanmış özeti. IP'nin kendisi
saklanmaz.

### Güvenlik notları

- Yetki tek yerde: `ADMIN_EPOSTALAR` listesinde olmayan Google hesabı, giriş yapsa
  bile 403 alır. Liste boşken kimse giremez.
- Oturum çerezi HMAC-SHA256 ile imzalı, `HttpOnly`, `Secure`, `SameSite=Lax` ve 12 saatlik.
- Panel yalnızca `src/content/`, `src/data/` ve `public/araclar/` altına yazabilir;
  yol denetimi `src/pages/api/admin/dosya.ts` içinde tek kapıdan geçer.
- `robots.txt` `/admin` adresini dışlar, sayfalar `noindex` gönderir, site haritasına girmez.

Panel yüzünden site tamamen statik olmaktan çıktı: içerik sayfaları hâlâ derleme
sırasında üretiliyor, yalnızca `/admin`, `/api/admin` ve araç uçları sunucu
tarafında çalışıyor. Vercel adaptörü bunun için duruyor.

## İçerik ekleme

Markdown dosyaları `src/content/` altında. Şema `src/content.config.ts` içinde tanımlı;
zorunlu bir alanı unutursanız derleme hata verir — bu kasıtlı.

Koleksiyonlar: `rehberler` (uzun rehberler), `ipuclari` (tek ekranlık notlar),
`komutlar` (komut kütüphanesi), `cozumler` (hızlı çözümler), `projeler`
(portfolyo). İçerik dosyaları `.mdx` biçiminde; render açısından markdown ile
aynı davranır.

Panelin gösterdiği hızlı alanlar `src/admin/icerik.ts` içinde tanımlı. Şemaya
zorunlu bir alan eklerseniz oraya da ekleyin — yoksa panelden oluşturulan kayıt
derlemeyi kırar.

Yapılandırma verisi `src/data/` altında ve panelden yönetilir:

| Dosya | Ne tutar |
| --- | --- |
| `src/data/ayarlar.json` | Site adı, alan adı, yazar, bülten, popüler aramalar |
| `src/data/konu/<slug>.json` | Her kategori ayrı dosya; slug = dosya adı |
| `src/data/menu.json` | Ana menü, kaynaklar menüsü, altlık sütunları, kümeler |

Yeni kategori eklemek `src/data/konu/` altına bir dosya eklemektir (ya da panelden
"Konular → +"). Menü, konu sayfası, OG kartı ve arşiv sayaçları kendiliğinden oluşur.

Yeni rehber: `src/content/rehberler/<slug>.mdx`

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

- `src/site.js` — ad-soyad, e-posta, sosyal hesaplar, bülten uç noktası
- `src/cv.js` — iş deneyimi, sertifikalar, SSS
- `src/content/projeler/*.md` — proje metrikleri

Alan adı yalnızca `src/site.js` içindeki `url` alanında tanımlı; canonical, OG adresleri,
RSS, site haritası ve `robots.txt` hepsi oradan türer. Değiştirmek için tek satır yeterli.

**Şu anki kişisel içeriğin tamamı uydurmadır** — iş yerleri, tarihler, sertifikalar ve proje
sayıları gerçekçi görünsün diye yazıldı. Yayına almadan önce değiştirin.

## Araçlar

Üreteçlerin kütüğü `src/araclar.js` içinde: menüdeki Araçlar sütunu, `/araclar`
dizini ve sayaçlar oradan türer. Yeni araç eklemek = sayfayı yazmak + listeye bir
satır eklemek.

Paylaşım kartı dışındaki üreteçlerin tamamı **tarayıcıda** çalışır; girilen veri
dışarı çıkmaz. Ortak mantık `src/scripts/` altında ve Node ile sınanabilir:

| Modül | Ne yapar | Nasıl doğrulandı |
| --- | --- | --- |
| `qr.js` | QR kodlayıcı: bayt kipi, sürüm 1–10, dört düzeltme seviyesi | Bağımsız bir kodlayıcının çıktısıyla modül modül karşılaştırma |
| `sertifika.js` | DER/X.509 ayrıştırıcı: süre, SAN, anahtar, imza | Node'un TLS ayrıştırıcısıyla üç gerçek sitede karşılaştırma |
| `cron.js` | Cron ayrıştırma, sonraki çalışmalar, Türkçe açıklama | Dönen zamanların ifadenin kısıtlarını sağladığı denetimi |
| `parola.js` | Rastgelelik, entropi, kırılma süresi, örüntü uyarıları | — |
| `sizinti.js` | Pwned Passwords k-anonimlik sorgusu (ilk 5 hane) | Bilinen sızıntı sayılarıyla karşılaştırma |

Test betikleri depoda tutulmuyor; `src/scripts/*.js` dosyaları düz ES modülü olduğu
için `node --input-type=module` ile doğrudan içe aktarılıp sınanabilir.

### Paylaşım kartı üreteci

`/araclar/paylasim-karti` bir adresi okuyup sosyal medya görselleri üretir. Kart
tuvalde çizilir, iki yetenek dışarıdan servis ister:

| Değişken | Ne için |
| --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | İkisinin de ortak hesap kimliği |
| `CLOUDFLARE_AI_TOKEN` | "AI arka plan üret" — Workers AI, FLUX.1-schnell |
| `CLOUDFLARE_TARAYICI_TOKEN` | "Site önizleme" stili — Browser Rendering ile ekran görüntüsü. AI jetonuna bu izin de verildiyse gerekmez |

Değişkenler tanımlı değilken araç çalışmaya devam eder: "Site önizleme" stili
önce ekran görüntüsünü dener, alamazsa sayfanın kendi `og:image` etiketine düşer,
o da yoksa tarayıcı penceresini sitenin renkleri ve logosuyla çizer. Durum satırı
hangi kaynağın kullanıldığını söyler.

## Bülten

`src/site.js` içindeki `newsletter.endpoint` boşken sayfalarda form yerine "sağlayıcı bağlanmadı"
notu görünür — kimse boşluğa abone olmaz. Sağlayıcının form uç noktasını yazdığınız anda form
etkinleşir; JavaScript varsa sayfadan ayrılmadan gönderir, yoksa normal form POST'u çalışır.

## Yayın

Statik çıktı, herhangi bir statik sunucuda çalışır.

- **Vercel** — `vercel.json` hazır: `framework: "astro"`, derleme `npm run build`, çıktı `dist`.
  Proje ön ayarı panelde Next.js'e kilitliyse `vercel.json` bunu geçersiz kılar; yine de hata
  alırsanız **Project Settings → Build & Deployment → Framework Preset** alanını *Astro* yapın.
- **Netlify** — `netlify.toml` hazır (`npm run build`, `dist`).
- **Cloudflare Pages** — derleme komutu `npm run build`, çıktı dizini `dist`.
- **GitHub Pages** — `src/site.js` içindeki `url` alanını `https://<kullanici>.github.io/<repo>`
  yapın ve `astro.config.mjs`'e `base: '/<repo>'` ekleyin; aksi hâlde bağlantılar ve OG adresleri kayar.

Önbellek ve güvenlik başlıkları iki yerde tanımlı çünkü sağlayıcılar farklı biçim okuyor:
`vercel.json` (Vercel) ve `public/_headers` (Netlify, Cloudflare Pages). Birini değiştirirseniz
diğerini de güncelleyin.

Adresler eğik çizgisiz (`/hakkimda`). `astro.config.mjs` içindeki `trailingSlash: 'never'`
ve `vercel.json` içindeki `trailingSlash: false` bu yüzden birlikte duruyor — canonical,
site haritası ve sunucu aynı biçimi kullanmazsa her adres bir yönlendirmeye takılır.

## SEO

Her sayfada `<title>`, meta description, canonical, Open Graph, Twitter card ve JSON-LD var:

- Yazılar → `TechArticle` + `BreadcrumbList`
- Hızlı çözümler → `HowTo` + `BreadcrumbList`
- Araç sayfaları → `SoftwareApplication` + `BreadcrumbList`
- Konu ve arşiv sayfaları → `CollectionPage`
- Projeler → `CreativeWork`
- Hakkımda → `ProfilePage` + `Person` + `FAQPage`
- Özgeçmiş → `Person` (`hasCredential`, `hasOccupation`)

Araç sayfalarının şeması `Base.astro` içinde adresten üretiliyor: `/araclar/<slug>`
kütükte (`src/data/araclar.json`) aranıp ad ve özet oradan alınıyor. 25 sayfaya tek tek
şema yazmak yerine yeni araç eklendiğinde şema kendiliğinden geliyor.

Site haritasındaki `<lastmod>` içerik dosyalarının ön bilgisinden okunuyor
(`guncelleme` varsa o, yoksa `yayin`). Yapılandırma Node tarafında çalıştığı için
koleksiyon API'si yok; `astro.config.mjs` içindeki `icerikTarihleri()` dosyaları
doğrudan tarıyor. Liste sayfaları en yeni içeriğin tarihini alıyor.

Yazı sayfaları ayrıca `article:published_time`, `article:modified_time`,
`article:section` ve `article:tag` gönderiyor — `makale` özelliğiyle.

Paylaşım kartları derleme sırasında satori + sharp ile üretilir. Yazı tipi
`src/assets/fonts/` altındaki statik Nunito WOFF dosyalarından okunur (satori woff2 okuyamaz).

## Tasarım

Renk mantığı: lacivert gövde metni, indigo eylem rengi, lavanta zemin blokları.
Kehribar ve yeşil dekor değil — kehribar dikkat/ipucu, yeşil doğrulanmış sonuç bildirir.
Tüm belirteçler `src/styles/global.css` başındaki `:root` bloğunda.

### Açık / karanlık tema

Her renk `light-dark(açık, karanlık)` ile **tek satırda** tanımlı; hangisinin geçerli
olacağını `color-scheme` söylüyor. Kökte `light dark` yazdığı için varsayılan işletim
sistemi tercihi; tema düğmesi kökteki `data-tema` özniteliğini yazınca `color-scheme`
tek değere sabitleniyor ve seçim sistemi eziyor. Seçim `localStorage`'daki `tema`
anahtarında; seçim yokken sistem teması değişirse sayfa da değişiyor.

Her belirteç iki kez yazılıyor — önce düz açık değer, sonra `light-dark()`. Eski
tarayıcı ikinci satırı geçersiz sayıp birincide kalıyor, yani renksiz bir sayfa değil
açık temayı görüyor.

Tema `Base.astro`'nun `<head>`'indeki **satır içi** betikle ilk boyamadan önce
uygulanıyor. Paketlenmiş betik geç kalıyor ve karanlık temada sayfa bir kare beyaz
yanıp sönüyor — bu yüzden `is:inline`.

**Rol ayrımı önemli:** `--indigo` dolgu rengi (üstüne beyaz yazı biniyor, karanlıkta da
koyu kalmalı), `--indigo-metin` yazı rengi (karanlıkta açılmalı). Tek değişkeni iki iş
için kullanmak iki temada birden okunabilir bir ton bırakmıyordu. Yeni bir yerde indigo
kullanırken: **yazıysa `--indigo-metin`, dolgu/kenarlıksa `--indigo`.** `accent-color`
bir dolgudur, `--indigo` alır.

Wi-Fi QR aracının tuval ve SVG renkleri (`#ffffff` / `#16203a`) bilerek sabit: karekod
okunabilirliği koyu-üstüne-açık gerektiriyor, misafir kartı da basılıyor.

Kontrast ölçümü: sayfaları bir `iframe`'de açıp `data-tema`yı yazın, geçişleri
`transition:none !important` ile kapatın (gizli sekmede duran geçiş eski rengi tutup
yanlış ölçüm veriyor), sonra her metin öğesinin efektif zeminine karşı oranını hesaplayın.
Eşik normal yazıda 4.5, 24 piksel üstü ya da 18.66 piksel kalın yazıda 3.

Tipografi tek aile: Nunito değişken ağırlık (300–1000), woff2 olarak gömülü ve `preload`
ediliyor. Türkçe karakterler için latin-ext alt kümesi ayrıca yükleniyor.

Tasarım önerilerinin ilk hâli `mockup/tema-onerileri.html` içinde duruyor.

## Performans

- **Önden çekme:** `prefetch: { prefetchAll: true, defaultStrategy: 'hover' }`. Fareyle
  bağlantının üzerine gelindiğinde sayfa indiriliyor. `viewport` yerine `hover` seçildi;
  bir listede 12+ bağlantı olduğu için görünür alan stratejisi gereksiz indirme yapıyor.
  `experimental.clientPrerender` destekleyen tarayıcılarda Speculation Rules'a geçiyor —
  sayfa yalnızca indirilmiyor, önden işleniyor da.
- **Önbellek:** `vercel.json` içinde `_astro`, `fonts`, `og` bir yıl `immutable`; HTML
  `s-maxage=600` + `stale-while-revalidate=604800` ile uç düğümde tutuluyor. Kurallar
  birbirinin üstüne yazmasın diye HTML kuralı diğer yolları olumsuz ileri bakışla dışlıyor.
- **Uzun listeler:** 78 ipucu ve 33 komut kartında `content-visibility: auto`; ekran
  dışındaki kartların düzeni ve boyaması erteleniyor.
- **Sayfa ağırlığı:** satır içi betik ve stil elden geldiğince ortak, önbelleklenen
  dosyalara taşındı. Ölçmek için: `dist/client/index.html` içindeki `<style>` ve
  `src` içermeyen `<script>` bloklarının toplam boyutuna bakın.

`public/_headers` Netlify/Cloudflare biçimindedir ve **Vercel'de çalışmaz**; taşınabilirlik
için duruyor. Vercel'de geçerli olan `vercel.json`.

## Erişilebilirlik ve mobil

- Markdown tabloları derleme sırasında `.tablo-sar` kapsayıcısına sarılıyor
  (`astro.config.mjs` içindeki `tablolariSar` rehype eklentisi). Dar ekranda sayfanın
  tamamı değil yalnızca tablo kayıyor; kapsayıcı `tabindex="0"` ile klavyeden de
  kaydırılabiliyor.
- Uzun kayıt defteri yolu, parametre ve adresler satır sonunda kırılıyor
  (`code { overflow-wrap: break-word }`); `pre` bundan muaf, orada kaydırma doğru davranış.
- Araç sayfalarının ızgarası `minmax(0, 1fr)` kullanıyor. Varsayılan `auto` sütun,
  içeriğinin en küçük genişliğinin altına inemediği için geniş sonuç tablosu olan
  araçlarda sayfanın tamamı yatay kayıyordu — sertifika okuyucuda 375 piksellik ekranda
  760 piksel taşma vardı. Araç sonuç tabloları da `display: block; overflow-x: auto`
  ile kendi içinde kayıyor (markdown olmadıkları için `tablo-sar`'a girmiyorlar).
- Başlıktaki "Bültene katıl" düğmesi 1040 pikselin altında gizleniyor. 900–1040 arasında
  başlık hâlâ masaüstü düzenindeydi ve toplam genişlik sığmıyordu. Seçici
  `.bas > .kap > .dg` — `.bas .dg` mega menünün içindeki düğmeyi de yakalıyor.
- Mobil menü sağdan açılan yan panel; arkadaki sayfa `.perde` ile kararıp bulanıklaşıyor.
- Palet kutusu 16 piksel yazı kullanıyor — iOS Safari daha küçük yazıda sayfayı
  yakınlaştırıyor.

Yatay taşmayı ölçmek için sayfaları 375 piksellik bir `iframe` içinde açıp
`documentElement.scrollWidth - 375` değerine bakın; `-4` beklenen (kaydırma çubuğu payı),
pozitif değer taşma demektir. Tüm araç sayfaları ve ana sayfa türleri bu yöntemle
375–1280 piksel arasında denendi.
