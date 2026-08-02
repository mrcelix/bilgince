---
baslik: "Bir portu hangi işlem tutuyor?"
ozet: "\"Bu port zaten kullanımda\" hatasında suçluyu iki komutla bulun."
konu: "windows"
etiketler: ["ag", "tanilama", "port"]
yayin: 2026-07-30
populerlik: 4
---

PowerShell'de tek satır yeter:

```powershell
Get-NetTCPConnection -LocalPort 443 -State Listen |
  Select-Object LocalAddress, LocalPort,
    @{ n='Islem'; e={ (Get-Process -Id $_.OwningProcess).ProcessName } },
    OwningProcess
```

Klasik yöntem de çalışır: `netstat -ano | findstr :443` çıktısındaki son sütun PID'dir, `tasklist /fi "pid eq <PID>"` ile adını bulursunuz.
