// Araç kütüğü: hem /araclar dizini hem başlıktaki Araçlar menüsü buradan
// besleniyor. Veri src/data/araclar.json içinde tutuluyor ki yönetim panelinden
// düzenlenebilsin; buradaki dışa aktarımlar sayfaların kullandığı arayüzü koruyor.
//
// Yeni araç eklerken: sayfayı yazın, JSON'a bir kayıt ekleyin. Menü, dizin ve
// sayaçlar kendiliğinden güncellenir.
import araclar from './data/araclar.json';

export const ARACLAR = araclar;

export const aracBul = (slug) => ARACLAR.find((a) => a.slug === slug);
