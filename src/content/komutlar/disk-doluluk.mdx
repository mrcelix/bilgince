---
baslik: "Sunuculardaki disk doluluğunu tek tabloda gör"
ozet: "Birden çok sunucunun boş alanını yüzdeyle listeler; %15'in altındakileri işaretler."
konu: "windows-server"
etiketler: ["izleme", "depolama"]
kod: |
  'sunucu01','sunucu02','sunucu03' | ForEach-Object {
    Get-CimInstance Win32_LogicalDisk -ComputerName $_ -Filter "DriveType=3" |
      Select-Object @{ n='Sunucu'; e={ $_.SystemName } }, DeviceID,
        @{ n='BosGB'; e={ [math]::Round($_.FreeSpace/1GB,1) } },
        @{ n='Bos%';  e={ [math]::Round($_.FreeSpace/$_.Size*100,1) } }
  } | Sort-Object 'Bos%' | Format-Table -AutoSize
dikkat: "Uzak sunucularda WinRM açık olmalı; kapalıysa Get-CimInstance -Protocol Dcom deneyin."
---
