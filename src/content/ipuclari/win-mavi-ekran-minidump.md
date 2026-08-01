---
baslik: "Mavi ekrandan sonra hangi sürücü suçlu?"
ozet: "Minidump dosyası hangi modülün çöktüğünü söyler; tahmin etmeye gerek yok."
konu: "windows"
etiketler: ["tanilama", "surucu", "cokme"]
yayin: 2026-07-08
populerlik: 26
---

Dökümler burada durur:

```
C:\Windows\Minidump\
```

Dosya yoksa döküm yazma kapalıdır; **Sistem Özellikleri → Gelişmiş → Başlangıç ve Kurtarma** altında "Küçük bellek dökümü" seçin.

Hızlı bir özet için olay günlüğüne bakın:

```powershell
Get-WinEvent -FilterHashtable @{ LogName='System'; Id=1001 } -MaxEvents 5 |
  Where-Object { $_.ProviderName -eq 'Microsoft-Windows-WER-SystemErrorReporting' } |
  Select-Object TimeCreated, Message
```

Ayrıntılı analiz için WinDbg ile dökümü açıp `!analyze -v` çalıştırın; çıktıdaki `MODULE_NAME` genellikle doğrudan sorumluyu verir.
