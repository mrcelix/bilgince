---
baslik: "Sunucuyu kim yeniden başlattı?"
ozet: "1074 olayı, kapatmayı başlatan kullanıcıyı ve gerekçesini kaydeder."
konu: "windows"
etiketler: ["olay-gunlugu", "tanilama", "windows-server"]
yayin: 2026-07-24
populerlik: 10
---

```powershell
Get-WinEvent -FilterHashtable @{ LogName='System'; Id=1074 } -MaxEvents 10 |
  Select-Object TimeCreated, @{ n='Mesaj'; e={ $_.Message -split "`n" | Select-Object -First 3 } }
```

1074, planlı kapatma ve yeniden başlatmaları kaydeder: hangi işlem başlattı, hangi kullanıcı, hangi gerekçe.

Beklenmeyen kapanmalar için **6008** ve **41** olaylarına bakın; ikisi birlikte elektrik kesintisi veya donanım kaynaklı ani kapanmayı işaret eder.
