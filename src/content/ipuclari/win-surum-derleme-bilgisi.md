---
baslik: "Windows sürüm ve derleme numarasını doğru okuyun"
ozet: "\"Windows 11\" yeterli bilgi değil; destek ve uyumluluk derleme numarasına bakar."
konu: "windows"
etiketler: ["envanter", "surum"]
yayin: 2026-07-04
populerlik: 30
---

Hızlı yol: **Win + R** → `winver`.

Betikte kullanmak için:

```powershell
Get-ComputerInfo -Property OsName, OsDisplayVersion, OsBuildNumber, OsHardwareAbstractionLayer
```

Uzaktan, birden çok makine için:

```powershell
'pc01','pc02','pc03' | ForEach-Object {
  [pscustomobject]@{
    Makine = $_
    Surum  = (Get-CimInstance Win32_OperatingSystem -ComputerName $_).Caption
    Derleme= (Get-CimInstance Win32_OperatingSystem -ComputerName $_).BuildNumber
  }
} | Format-Table -AutoSize
```

Destek ömrü hesaplarken `OsDisplayVersion` (örn. 24H2) alanına bakın; ana sürüm numarası tek başına yeterli değildir.
