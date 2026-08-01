---
baslik: "Makine ne zamandır açık, ne zaman kuruldu?"
ozet: "\"Yeniden başlattım\" ifadesini doğrulamanın ve makine yaşını öğrenmenin iki komutu."
konu: "windows"
etiketler: ["envanter", "tanilama"]
yayin: 2026-06-16
populerlik: 48
---

```powershell
$os = Get-CimInstance Win32_OperatingSystem
[pscustomobject]@{
  Makine        = $env:COMPUTERNAME
  SonAcilis     = $os.LastBootUpTime
  CalismaSuresi = (Get-Date) - $os.LastBootUpTime
  KurulumTarihi = $os.InstallDate
}
```

`CalismaSuresi` haftalarcaysa ve kullanıcı "her gün kapatıyorum" diyorsa sebep genelde hızlı başlatmadır: kapatma tam kapatma değildir.

Hızlı bakış için:

```cmd
systeminfo | findstr /C:"Sistem Önyükleme Zamanı" /C:"Özgün Yükleme Tarihi"
```

Kurulum tarihi, makinenin yaşını ve yenileme sırasını planlarken envanter tablosuna girmesi gereken alandır.
