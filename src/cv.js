// Özgeçmiş verisi — /ozgecmis, /hakkimda ve Person şeması buradan beslenir.
//
// Veri src/data/ozgecmis.json içinde tutuluyor ki yönetim panelinden (/admin/veri)
// düzenlenebilsin; buradaki dışa aktarımlar sayfaların kullandığı arayüzü koruyor.
//
// YER TUTUCU: içerik uydurmadır, gerçek bilgilerinizle değiştirin.
import ozgecmis from './data/ozgecmis.json';

export const DENEYIM = ozgecmis.deneyim;
export const SERTIFIKALAR = ozgecmis.sertifikalar;
export const SSS = ozgecmis.sss;
