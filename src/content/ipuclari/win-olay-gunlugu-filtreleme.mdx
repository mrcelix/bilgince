---
baslik: "Olay günlüğünü hızlı filtreleyin"
ozet: "Get-EventLog yavaş ve eski. FilterHashtable ile sorgu, günlüğün kendisinde çalışır."
konu: "windows"
etiketler: ["olay-gunlugu", "powershell", "tanilama"]
yayin: 2026-06-18
populerlik: 45
---

```powershell
Get-WinEvent -FilterHashtable @{
  LogName   = 'System'
  Level     = 1,2                      # Kritik ve Hata
  StartTime = (Get-Date).AddHours(-24)
} | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object Count, Name
```

`Get-EventLog` tüm kayıtları çekip sonra süzer; büyük günlüklerde dakikalar sürer. `FilterHashtable` süzmeyi günlük servisine yaptırır ve saniyeler içinde döner.

Uzak makinede aynı sorgu:

```powershell
Get-WinEvent -ComputerName sunucu01 -FilterHashtable @{ LogName='Application'; Level=2 } -MaxEvents 20
```

Grup sonucundaki en üstteki sağlayıcı, o makinedeki gürültünün kaynağıdır — sorunu aramaya oradan başlayın.
