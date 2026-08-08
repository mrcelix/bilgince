/**
 * Cron ifadesi çözümleyici: beş alanlı standart söz dizimi (dakika saat
 * ayın-günü ay haftanın-günü) + @gunluk gibi kısayollar.
 *
 * İki iş yapar: ifadeyi Türkçe cümleye çevirir ve sonraki çalışma zamanlarını
 * hesaplar. İkincisi olmadan ilki yeterli değil — "0 0 31 2 *" cümleye çevrilir
 * ama hiçbir zaman çalışmaz.
 */

const AY_ADI = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
const GUN_ADI = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];

const AY_KOD = { JAN: 1, FEB: 2, MAR: 3, APR: 4, MAY: 5, JUN: 6, JUL: 7, AUG: 8, SEP: 9, OCT: 10, NOV: 11, DEC: 12 };
const GUN_KOD = { SUN: 0, MON: 1, TUE: 2, WED: 3, THU: 4, FRI: 5, SAT: 6 };

const KISAYOL = {
  '@yearly': '0 0 1 1 *',
  '@annually': '0 0 1 1 *',
  '@monthly': '0 0 1 * *',
  '@weekly': '0 0 * * 0',
  '@daily': '0 0 * * *',
  '@midnight': '0 0 * * *',
  '@hourly': '0 * * * *',
};

const ALANLAR = [
  { ad: 'dakika', enAz: 0, enCok: 59 },
  { ad: 'saat', enAz: 0, enCok: 23 },
  { ad: 'ayGunu', enAz: 1, enCok: 31 },
  { ad: 'ay', enAz: 1, enCok: 12 },
  { ad: 'haftaGunu', enAz: 0, enCok: 7 }, // 7 = pazar, 0 gibi
];

// Tek bir alanı ("*/15", "1-5", "MON,WED") değer kümesine çevirir.
function alanCoz(ham, alan) {
  const kume = new Set();
  const metin = String(ham).toUpperCase();

  for (const parca of metin.split(',')) {
    const [aralik, adimHam] = parca.split('/');
    const adim = adimHam === undefined ? 1 : Number(adimHam);
    if (!Number.isInteger(adim) || adim < 1) throw new Error(`Geçersiz adım: ${parca}`);

    let bas;
    let son;
    if (aralik === '*') {
      bas = alan.enAz;
      son = alan.enCok;
    } else if (aralik.includes('-')) {
      const [a, b] = aralik.split('-').map((x) => sayiCoz(x, alan));
      bas = a;
      son = b;
    } else {
      bas = sayiCoz(aralik, alan);
      son = adimHam === undefined ? bas : alan.enCok;
    }

    if (bas > son) throw new Error(`Aralık ters: ${parca}`);
    for (let d = bas; d <= son; d += adim) kume.add(d);
  }

  if (!kume.size) throw new Error(`${alan.ad} alanı boş kaldı`);
  return kume;
}

function sayiCoz(metin, alan) {
  const kod = alan.ad === 'ay' ? AY_KOD[metin] : alan.ad === 'haftaGunu' ? GUN_KOD[metin] : undefined;
  const deger = kod ?? Number(metin);
  if (!Number.isInteger(deger) || deger < alan.enAz || deger > alan.enCok) {
    throw new Error(`${alan.ad} için geçersiz değer: ${metin} (${alan.enAz}–${alan.enCok})`);
  }
  return deger;
}

export function cronAyristir(ifade) {
  const temiz = String(ifade).trim().toLowerCase();
  const acilmis = KISAYOL[temiz] ?? ifade;
  const parcalar = String(acilmis).trim().split(/\s+/);

  if (parcalar.length !== 5) {
    throw new Error(`Beş alan bekleniyor, ${parcalar.length} alan verildi. Örnek: 30 3 * * 1-5`);
  }

  const kumeler = ALANLAR.map((alan, i) => alanCoz(parcalar[i], alan));
  // 7 ve 0 aynı gün: pazar
  if (kumeler[4].has(7)) kumeler[4].add(0);

  return {
    ham: parcalar.join(' '),
    dakika: kumeler[0],
    saat: kumeler[1],
    ayGunu: kumeler[2],
    ay: kumeler[3],
    haftaGunu: kumeler[4],
    ayGunuYildiz: parcalar[2] === '*',
    haftaGunuYildiz: parcalar[4] === '*',
  };
}

/**
 * Vixie cron kuralı: ayın günü ve haftanın günü ikisi de sınırlıysa gün
 * eşleşmesi VEYA'dır — ikisinden biri tutarsa çalışır. Bu, "her ayın 1'i ve her
 * pazartesi" gibi ifadelerin neden beklenenden sık çalıştığının cevabıdır.
 */
function gunUyar(c, tarih) {
  const ayGunuUyar = c.ayGunu.has(tarih.getDate());
  const haftaUyar = c.haftaGunu.has(tarih.getDay());
  if (c.ayGunuYildiz && c.haftaGunuYildiz) return true;
  if (c.ayGunuYildiz) return haftaUyar;
  if (c.haftaGunuYildiz) return ayGunuUyar;
  return ayGunuUyar || haftaUyar;
}

/** @returns {Date[]} sonraki çalışma zamanları (yerel saat) */
export function sonrakiCalismalar(ifade, adet = 5, baslangic = new Date()) {
  const c = typeof ifade === 'string' ? cronAyristir(ifade) : ifade;
  const sonuc = [];

  const t = new Date(baslangic.getTime());
  t.setSeconds(0, 0);
  t.setMinutes(t.getMinutes() + 1);

  // 25 yıl: "0 0 29 2 *" için beş çalışma ancak bu pencerede toplanır. Gün
  // tutmadığında döngü bir gün birden atladığı için tarama ucuz kalıyor.
  const sinir = new Date(t.getTime() + 25 * 366 * 24 * 60 * 60 * 1000);

  while (sonuc.length < adet && t < sinir) {
    if (!c.ay.has(t.getMonth() + 1) || !gunUyar(c, t)) {
      // gün tutmuyorsa saat saat ilerlemeye gerek yok
      t.setDate(t.getDate() + 1);
      t.setHours(0, 0, 0, 0);
      continue;
    }
    if (!c.saat.has(t.getHours())) {
      t.setHours(t.getHours() + 1, 0, 0, 0);
      continue;
    }
    if (!c.dakika.has(t.getMinutes())) {
      t.setMinutes(t.getMinutes() + 1, 0, 0);
      continue;
    }
    sonuc.push(new Date(t.getTime()));
    t.setMinutes(t.getMinutes() + 1, 0, 0);
  }
  return sonuc;
}

/* ---------------------------------------------------------- açıklama üretimi */

/**
 * "ayın 1'i", "ayın 3'ü", "ayın 29'u" — sayıya göre değişen iyelik eki.
 * Sondaki basamak belirler; 10, 20 ve 30 kendi istisnalarıdır.
 */
function ayinGunu(n) {
  const istisna = { 10: 'u', 20: 'si', 30: 'u' };
  const ek = istisna[n] ?? { 1: 'i', 2: 'si', 3: 'ü', 4: 'ü', 5: 'i', 6: 'sı', 7: 'si', 8: 'i', 9: 'u', 0: 'ı' }[n % 10];
  return `${n}'${ek}`;
}

function listele(kume, bicim = (v) => String(v)) {
  const dizi = [...kume].sort((a, b) => a - b).map(bicim);
  if (dizi.length === 1) return dizi[0];
  return dizi.slice(0, -1).join(', ') + ' ve ' + dizi[dizi.length - 1];
}

// Küme düzenli aralıklı mı? Adımlı ifadeleri ("*/15") cümlede sadeleştirir.
function adimBul(kume, enAz, enCok) {
  const dizi = [...kume].sort((a, b) => a - b);
  if (dizi.length < 3 || dizi[0] !== enAz) return null;
  const adim = dizi[1] - dizi[0];
  for (let i = 2; i < dizi.length; i++) if (dizi[i] - dizi[i - 1] !== adim) return null;
  return dizi[dizi.length - 1] + adim > enCok ? adim : null;
}

export function cronAciklama(ifade) {
  const c = typeof ifade === 'string' ? cronAyristir(ifade) : ifade;
  const parcalar = [];

  /* saat ve dakika */
  const dakikaAdim = adimBul(c.dakika, 0, 59);
  const saatAdim = adimBul(c.saat, 0, 23);
  const tumSaat = c.saat.size === 24;
  const tumDakika = c.dakika.size === 60;

  if (tumDakika && tumSaat) parcalar.push('Her dakika');
  else if (dakikaAdim && tumSaat) parcalar.push(`Her ${dakikaAdim} dakikada bir`);
  else if (dakikaAdim) parcalar.push(`Her ${dakikaAdim} dakikada bir`);
  else if (tumSaat && c.dakika.size === 1) parcalar.push(`Her saat başı ${listele(c.dakika)}. dakikada`);
  else if (c.dakika.size === 1 && c.saat.size === 1) {
    const s = [...c.saat][0];
    const d = [...c.dakika][0];
    parcalar.push(`Saat ${String(s).padStart(2, '0')}:${String(d).padStart(2, '0')}`);
  } else parcalar.push(`${listele(c.dakika)}. dakikalarda`);

  /* saat kısıtı ayrı cümlecik olarak */
  if (!tumSaat && !(c.dakika.size === 1 && c.saat.size === 1)) {
    if (saatAdim) parcalar.push(`her ${saatAdim} saatte bir`);
    else parcalar.push(`${listele(c.saat, (v) => String(v).padStart(2, '0') + ':00')} saatlerinde`);
  }

  /* günler */
  const gunler = [];
  if (!c.haftaGunuYildiz) {
    const hafta = [...c.haftaGunu].filter((g) => g < 7);
    gunler.push(listele(new Set(hafta), (g) => GUN_ADI[g]) + ' günleri');
  }
  if (!c.ayGunuYildiz) {
    gunler.push('ayın ' + listele(c.ayGunu, ayinGunu));
  }
  if (gunler.length === 2) parcalar.push(gunler.join(' veya '));
  else if (gunler.length === 1) parcalar.push(gunler[0]);
  else parcalar.push('her gün');

  /* aylar */
  if (c.ay.size !== 12) parcalar.push('yalnızca ' + listele(c.ay, (a) => AY_ADI[a - 1]) + ' aylarında');

  return parcalar.join(', ') + '.';
}

/** Zamanlanmış Görevler için kaba PowerShell karşılığı (tetikleyici satırı) */
export function powershellKarsilik(ifade) {
  const c = typeof ifade === 'string' ? cronAyristir(ifade) : ifade;
  const saat = [...c.saat].sort((a, b) => a - b)[0];
  const dakika = [...c.dakika].sort((a, b) => a - b)[0];
  const zaman = `${String(saat).padStart(2, '0')}:${String(dakika).padStart(2, '0')}`;
  const dakikaAdim = adimBul(c.dakika, 0, 59);

  if (dakikaAdim && c.saat.size === 24) {
    return `New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes ${dakikaAdim})`;
  }
  if (!c.haftaGunuYildiz) {
    const ingilizce = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const gunler = [...c.haftaGunu].filter((g) => g < 7).map((g) => ingilizce[g]).join(',');
    return `New-ScheduledTaskTrigger -Weekly -DaysOfWeek ${gunler} -At ${zaman}`;
  }
  if (!c.ayGunuYildiz) {
    return `# Aylık tetikleyici için: schtasks /Create /SC MONTHLY /D ${[...c.ayGunu].join(',')} /ST ${zaman}`;
  }
  return `New-ScheduledTaskTrigger -Daily -At ${zaman}`;
}
