---
baslik: "Açılışta çalışan programları gerçekten kontrol edin"
ozet: "Görev Yöneticisi her şeyi göstermez. Başlangıç klasörü, zamanlanmış görevler ve kayıt defteri de bakılmalı."
konu: "windows"
etiketler: ["baslangic", "performans"]
yayin: 2026-07-20
populerlik: 15
---

Görev Yöneticisi → **Başlangıç uygulamaları** ilk duraktır, ama tek durak değildir.

Başlangıç klasörleri:

```
shell:startup          → yalnızca bu kullanıcı
shell:common startup   → tüm kullanıcılar
```

Kayıt defteri girdileri:

```powershell
'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' |
  ForEach-Object { Get-ItemProperty $_ } | Format-List
```

Bir de açılışta tetiklenen zamanlanmış görevler var:

```powershell
Get-ScheduledTask | Where-Object { $_.Triggers.CimClass.CimClassName -match 'Logon|Boot' } |
  Select-Object TaskName, TaskPath, State
```
