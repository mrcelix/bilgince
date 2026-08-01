---
baslik: "Kilitlenen hesabın kaynağını tahminle aramayı bırakın"
ozet: "4740 olayı yalnızca PDC emulator'de güvenilir. Caller Computer Name alanı kaynağı doğrudan söyler."
konu: "powershell"
etiketler: ["active-directory", "olay-gunlugu"]
yayin: 2026-08-01
sure: 2
populerlik: 6
gununIpucu: true
terminalBaslik: "PowerShell 7 · DC01"
komut: |
  # hesabı kim kilitliyor?
  PS> Get-WinEvent -ComputerName (netdom query fsmo) `
        -FilterHashtable @{ LogName='Security'; Id=4740 } -Max 5
cikti: |
  TimeCreated      Hesap     Kaynak
  28.07 09:14:02   m.demir   PRN-KAT3
  28.07 09:14:31   m.demir   PRN-KAT3
---

Kullanıcı "hesabım sürekli kilitleniyor" dediğinde önce **PDC emulator** rolünü tutan domain controller'a bakın — 4740 olayı yalnızca orada güvenilir biçimde toplanır. **Caller Computer Name** alanı kaynağı doğrudan söyler; neredeyse her zaman eski bir eşlenmiş sürücü veya kayıtlı bir hizmet hesabıdır.

```powershell
Get-WinEvent -ComputerName (netdom query fsmo) -FilterHashtable @{
  LogName = 'Security'; Id = 4740
} -MaxEvents 5
```
