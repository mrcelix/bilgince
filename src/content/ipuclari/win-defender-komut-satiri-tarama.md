---
baslik: "Defender taramasını komut satırından çalıştırın"
ozet: "Uzak makinede arayüz açmadan tarama başlatmak ve imzaları güncellemek."
konu: "windows"
etiketler: ["guvenlik", "defender"]
yayin: 2026-06-30
populerlik: 34
---

```powershell
Update-MpSignature
Start-MpScan -ScanType QuickScan          # veya FullScan
Get-MpThreatDetection | Select-Object -First 10 InitialDetectionTime, ThreatID, Resources
```

Belirli bir klasörü taramak:

```powershell
Start-MpScan -ScanType CustomScan -ScanPath "D:\Paylasim"
```

Koruma durumunu tek bakışta görmek:

```powershell
Get-MpComputerStatus | Select-Object AMServiceEnabled, RealTimeProtectionEnabled,
  AntivirusSignatureLastUpdated, QuickScanAge
```

`AntivirusSignatureLastUpdated` birkaç günden eskiyse imza güncellemesi çalışmıyordur — tarama başlatmadan önce onu çözün.
