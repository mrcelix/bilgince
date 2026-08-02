import { config, collection, singleton, fields } from '@keystatic/core';

/* --------------------------------------------------------------------------
   Admin paneli. Yerelde dosya sistemine, canlıda GitHub deposuna yazar.
   Yerel: npm run dev → http://localhost:4321/keystatic
   Canlı: https://bilgince.com/keystatic (GitHub App gerektirir, README'ye bakın)
   -------------------------------------------------------------------------- */

// Bu dosya tarayıcıya da paketleniyor: `process` burada tanımlı değil,
// Vite'ın import.meta.env değişkenleri kullanılmalı.
const gitHubModu =
  import.meta.env.PUBLIC_KEYSTATIC_STORAGE === 'github' || import.meta.env.PROD;

const IKONLAR = [
  { label: 'Bulut', value: 'bulut' },
  { label: 'Sunucu', value: 'sunucu' },
  { label: 'Pencere', value: 'pencere' },
  { label: 'Terminal', value: 'terminal' },
  { label: 'Kutu', value: 'kutu' },
  { label: 'Küre', value: 'kure' },
  { label: 'Düğüm', value: 'dugum' },
  { label: 'Kalkan', value: 'kalkan' },
  { label: 'Akış', value: 'akis' },
  { label: 'Geri', value: 'geri' },
] as const;

export default config({
  storage: gitHubModu
    ? { kind: 'github', repo: { owner: 'mrcelix', name: 'bilgince' } }
    : { kind: 'local' },

  ui: {
    brand: { name: 'bilgince' },
    navigation: {
      İçerik: ['rehberler', 'ipuclari', 'komutlar'],
      Portfolyo: ['projeler'],
      Yapılandırma: ['konular', 'menu', 'ayarlar'],
    },
  },

  collections: {
    // ---------------------------------------------------------------- rehberler
    rehberler: collection({
      label: 'Rehberler',
      slugField: 'baslik',
      path: 'src/content/rehberler/*',
      format: { contentField: 'content' },
      entryLayout: 'content',
      columns: ['baslik', 'konu', 'yayin'],
      schema: {
        baslik: fields.slug({
          name: { label: 'Başlık', validation: { length: { min: 8 } } },
          slug: {
            label: 'Adres (slug)',
            description: 'Yayınlandıktan sonra değiştirmeyin — kalıcı bağlantı kırılır.',
          },
        }),
        ozet: fields.text({
          label: 'Özet',
          description: 'Meta açıklama olarak da kullanılır. 155 karakteri geçmesin.',
          multiline: true,
          validation: { length: { min: 40, max: 300 } },
        }),
        seoBaslik: fields.text({
          label: 'SEO başlığı',
          description: 'Boş bırakılırsa başlık kullanılır.',
        }),
        konu: fields.relationship({
          label: 'Konu',
          collection: 'konular',
          description: 'Konu listesi Yapılandırma → Konular altından yönetilir.',
        }),
        etiketler: fields.array(fields.text({ label: 'Etiket' }), {
          label: 'Etiketler',
          itemLabel: (props) => props.value,
        }),
        yayin: fields.date({ label: 'Yayın tarihi', validation: { isRequired: true } }),
        guncelleme: fields.date({
          label: 'Son güncelleme',
          description: 'Doldurulursa yazının üstünde "son güncelleme" rozeti çıkar.',
        }),
        sure: fields.integer({
          label: 'Okuma süresi (dk)',
          validation: { isRequired: true, min: 1, max: 90 },
        }),
        seri: fields.text({ label: 'Seri adı', description: 'Boş bırakılabilir.' }),
        seriSira: fields.integer({ label: 'Seri sırası' }),
        oneCikan: fields.checkbox({ label: 'Ana sayfada baş yazı olsun' }),
        taslak: fields.checkbox({ label: 'Taslak (hiçbir yerde görünmez)' }),
        content: fields.mdx({ label: 'İçerik' }),
      },
    }),

    // ----------------------------------------------------------------- ipuçları
    ipuclari: collection({
      label: 'Hızlı ipuçları',
      slugField: 'baslik',
      path: 'src/content/ipuclari/*',
      format: { contentField: 'content' },
      entryLayout: 'content',
      columns: ['baslik', 'konu', 'populerlik'],
      schema: {
        baslik: fields.slug({ name: { label: 'Başlık' } }),
        ozet: fields.text({ label: 'Özet', multiline: true }),
        konu: fields.relationship({ label: 'Konu', collection: 'konular' }),
        etiketler: fields.array(fields.text({ label: 'Etiket' }), {
          label: 'Etiketler',
          itemLabel: (props) => props.value,
        }),
        yayin: fields.date({ label: 'Yayın tarihi', validation: { isRequired: true } }),
        sure: fields.integer({ label: 'Okuma süresi (dk)', defaultValue: 2 }),
        populerlik: fields.integer({
          label: 'İlgi sırası',
          description: '1 = en çok ilgi gören. Liste bu değere göre sıralanır.',
          defaultValue: 999,
        }),
        gununIpucu: fields.checkbox({ label: 'Ana sayfada "günün ipucu" olsun' }),
        terminalBaslik: fields.text({ label: 'Terminal başlığı', defaultValue: 'PowerShell 7' }),
        komut: fields.text({ label: 'Terminal komutu', multiline: true }),
        cikti: fields.text({ label: 'Terminal çıktısı', multiline: true }),
        content: fields.mdx({ label: 'İçerik' }),
      },
    }),

    // ----------------------------------------------------------------- komutlar
    komutlar: collection({
      label: 'Komut kütüphanesi',
      slugField: 'baslik',
      path: 'src/content/komutlar/*',
      format: { contentField: 'content' },
      columns: ['baslik', 'konu'],
      schema: {
        baslik: fields.slug({ name: { label: 'Başlık' } }),
        ozet: fields.text({ label: 'Ne işe yarar', multiline: true }),
        konu: fields.relationship({ label: 'Konu', collection: 'konular' }),
        etiketler: fields.array(fields.text({ label: 'Etiket' }), {
          label: 'Etiketler',
          itemLabel: (props) => props.value,
        }),
        kod: fields.text({ label: 'Komut', multiline: true, validation: { isRequired: true } }),
        dikkat: fields.text({
          label: 'Uyarı',
          description: 'Nerede patlayabileceği. Kehribar kutuda gösterilir.',
          multiline: true,
        }),
        ilgiliRehber: fields.text({ label: 'İlgili rehber (slug)' }),
        content: fields.mdx({ label: 'Ek not' }),
      },
    }),

    // ----------------------------------------------------------------- projeler
    projeler: collection({
      label: 'Portfolyo projeleri',
      slugField: 'baslik',
      path: 'src/content/projeler/*',
      format: { contentField: 'content' },
      entryLayout: 'content',
      columns: ['baslik', 'yil'],
      schema: {
        baslik: fields.slug({ name: { label: 'Proje adı' } }),
        ozet: fields.text({ label: 'Özet', multiline: true }),
        rol: fields.text({ label: 'Rolünüz' }),
        sureMetni: fields.text({ label: 'Süre', description: 'Örn: 6 hafta' }),
        yil: fields.text({ label: 'Yıl', description: 'Örn: 2025–2026' }),
        kapsam: fields.text({ label: 'Kapsam', description: 'Örn: 3 lokasyon' }),
        sorun: fields.text({ label: 'Sorun', multiline: true }),
        yaklasim: fields.text({ label: 'Yaklaşım', multiline: true }),
        sonuc: fields.text({ label: 'Sonuç', multiline: true }),
        teknolojiler: fields.array(fields.text({ label: 'Teknoloji' }), {
          label: 'Teknolojiler',
          itemLabel: (props) => props.value,
        }),
        metrikler: fields.array(
          fields.object({
            deger: fields.text({ label: 'Değer', description: 'Örn: %92' }),
            etiket: fields.text({ label: 'Etiket', description: 'Örn: İlk hafta MFA kaydı' }),
          }),
          { label: 'Sonuç metrikleri', itemLabel: (props) => `${props.fields.deger.value} — ${props.fields.etiket.value}` }
        ),
        asamalar: fields.array(
          fields.object({
            baslik: fields.text({ label: 'Aşama' }),
            aciklama: fields.text({ label: 'Açıklama', multiline: true }),
            zaman: fields.text({ label: 'Zaman', description: 'Örn: 1.–2. hafta' }),
          }),
          { label: 'Uygulama sırası', itemLabel: (props) => props.fields.baslik.value }
        ),
        ilgiliRehberler: fields.array(fields.text({ label: 'Rehber slug' }), {
          label: 'İlgili rehberler',
          itemLabel: (props) => props.value,
        }),
        sira: fields.integer({ label: 'Sıra', defaultValue: 0 }),
        content: fields.mdx({ label: 'Notlar' }),
      },
    }),

    // ------------------------------------------------ konular (kategori yönetimi)
    konular: collection({
      label: 'Konular (kategoriler)',
      slugField: 'ad',
      path: 'src/data/konu/*',
      format: { data: 'json' },
      columns: ['ad', 'grup'],
      schema: {
        ad: fields.slug({
          name: { label: 'Konu adı' },
          slug: { label: 'Adres (slug)', description: '/konu/<slug> adresinde kullanılır.' },
        }),
        ozet: fields.text({ label: 'Tek satırlık açıklama', multiline: true }),
        grup: fields.text({
          label: 'Küme',
          description: 'Mega menüde hangi sütuna düşeceği. Kümeler Menü ekranında tanımlı.',
        }),
        ikon: fields.select({ label: 'İkon', options: [...IKONLAR], defaultValue: 'kutu' }),
        sira: fields.integer({ label: 'Sıra', defaultValue: 50 }),
        oneCikan: fields.checkbox({
          label: 'Öne çıkan konu',
          description: 'Ana sayfada ve menüde vurgulanır.',
        }),
      },
    }),
  },

  singletons: {
    // -------------------------------------------------------------- site ayarları
    ayarlar: singleton({
      label: 'Site ayarları',
      path: 'src/data/ayarlar',
      format: { data: 'json' },
      schema: {
        ad: fields.text({ label: 'Site adı' }),
        adres: fields.url({ label: 'Alan adı', description: 'https:// ile, sonunda eğik çizgi yok.' }),
        baslik: fields.text({ label: 'Site başlığı (title)' }),
        aciklama: fields.text({ label: 'Site açıklaması (meta description)', multiline: true }),
        yazar: fields.object({
          ad: fields.text({ label: 'Ad soyad' }),
          basHarfler: fields.text({ label: 'Baş harfler' }),
          unvan: fields.text({ label: 'Unvan' }),
          kurum: fields.text({ label: 'Kurum' }),
          sehir: fields.text({ label: 'Şehir' }),
          eposta: fields.text({ label: 'E-posta' }),
          linkedin: fields.text({ label: 'LinkedIn adresi' }),
          github: fields.text({ label: 'GitHub adresi' }),
          uzmanlik: fields.array(fields.text({ label: 'Yetkinlik' }), {
            label: 'Yetkinlikler',
            itemLabel: (props) => props.value,
          }),
        }, { label: 'Yazar' }),
        bulten: fields.object({
          aboneSayisi: fields.integer({ label: 'Abone sayısı' }),
          sikligi: fields.text({ label: 'Sıklık metni' }),
          vaat: fields.text({ label: 'Bülten vaadi', multiline: true }),
          endpoint: fields.text({
            label: 'Sağlayıcı uç noktası',
            description: 'Boş bırakılırsa form yerine "bağlanmadı" notu görünür.',
          }),
          alanAdi: fields.text({ label: 'E-posta alan adı', defaultValue: 'email' }),
        }, { label: 'Bülten' }),
        populerAramalar: fields.array(fields.text({ label: 'Arama' }), {
          label: 'Popüler aramalar',
          itemLabel: (props) => props.value,
        }),
        sayfaBasi: fields.integer({ label: 'Arşiv sayfası başına yazı', defaultValue: 12 }),
      },
    }),

    // ---------------------------------------------------------------------- menü
    menu: singleton({
      label: 'Menü',
      path: 'src/data/menu',
      format: { data: 'json' },
      schema: {
        anaMenu: fields.array(
          fields.object({
            etiket: fields.text({ label: 'Etiket' }),
            tur: fields.select({
              label: 'Tür',
              options: [
                { label: 'Normal bağlantı', value: 'bag' },
                { label: 'Mega menü — Konular', value: 'mega-konular' },
                { label: 'Mega menü — Kaynaklar', value: 'mega-kaynaklar' },
              ],
              defaultValue: 'bag',
            }),
            adres: fields.text({ label: 'Adres' }),
          }),
          { label: 'Ana menü', itemLabel: (props) => props.fields.etiket.value }
        ),
        araclar: fields.array(
          fields.object({
            etiket: fields.text({ label: 'Etiket' }),
            adres: fields.text({ label: 'Adres' }),
            aciklama: fields.text({ label: 'Açıklama' }),
            ikon: fields.select({ label: 'İkon', options: [...IKONLAR], defaultValue: 'kutu' }),
            sayac: fields.select({
              label: 'Sayaç',
              options: [
                { label: 'Yok', value: 'yok' },
                { label: 'Rehber sayısı', value: 'rehberler' },
                { label: 'İpucu sayısı', value: 'ipuclari' },
                { label: 'Komut sayısı', value: 'komutlar' },
              ],
              defaultValue: 'yok',
            }),
          }),
          { label: 'Kaynaklar menüsü', itemLabel: (props) => props.fields.etiket.value }
        ),
        altlik: fields.array(
          fields.object({
            baslik: fields.text({ label: 'Sütun başlığı' }),
            baglantilar: fields.array(
              fields.object({
                etiket: fields.text({ label: 'Etiket' }),
                adres: fields.text({ label: 'Adres' }),
              }),
              { label: 'Bağlantılar', itemLabel: (props) => props.fields.etiket.value }
            ),
          }),
          { label: 'Altlık sütunları', itemLabel: (props) => props.fields.baslik.value }
        ),
      },
    }),
  },
});
