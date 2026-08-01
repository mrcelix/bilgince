---
baslik: "Açılışta betik çalıştırmanın doğru yolu"
ozet: "Başlangıç klasörüne kısayol atmak yerine zamanlanmış görev kullanın: yönetici yetkisi, gecikme ve günlük kaydı gelir."
konu: "windows"
etiketler: ["otomasyon", "zamanlanmis-gorev"]
yayin: 2026-06-22
populerlik: 41
---

```powershell
$eylem   = New-ScheduledTaskAction -Execute 'pwsh.exe' `
             -Argument '-NoProfile -File "C:\Betikler\acilis.ps1"'
$tetik   = New-ScheduledTaskTrigger -AtStartup
$ayar    = New-ScheduledTaskSettingsSet -StartWhenAvailable `
             -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
$asil    = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest

Register-ScheduledTask -TaskName 'Acilis-Bakim' -Action $eylem -Trigger $tetik `
  -Settings $ayar -Principal $asil
```

Başlangıç klasörüne kısayol koymanın üç eksiği vardır: yönetici yetkisiyle çalışmaz, oturum açılmadan tetiklenmez ve başarısız olduğunda hiçbir iz bırakmaz. Zamanlanmış görev üçünü de çözer.

Görevin gerçekten çalıştığını doğrulayın:

```powershell
Get-ScheduledTaskInfo -TaskName 'Acilis-Bakim' |
  Select-Object LastRunTime, LastTaskResult, NextRunTime
```

`LastTaskResult` değeri 0 ise başarılıdır.
