---
baslik: "Disk ölmeden önce haber verir: sağlık durumunu okuyun"
ozet: "SMART verisi Windows üzerinden okunabilir; yavaşlama şikâyetinde ilk bakılacak yerlerden biri."
konu: "windows"
etiketler: ["donanim", "disk", "tanilama"]
yayin: 2026-06-18
populerlik: 46
---

```powershell
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, Size
Get-PhysicalDisk | Get-StorageReliabilityCounter |
  Select-Object DeviceId, Wear, ReadErrorsTotal, WriteErrorsTotal, Temperature
```

`HealthStatus` **Warning** veya **Unhealthy** ise diski değiştirin; "henüz çalışıyor" bir gerekçe değildir.

SSD'lerde `Wear` değeri kullanılmış ömür yüzdesini verir. 80'in üzerindeyse değişim planlayın.

Basit kontrol için:

```cmd
wmic diskdrive get model,status
```

`Pred Fail` görürseniz disk kendi arızasını önceden bildiriyordur — o makinede yedeğin güncelliğini hemen doğrulayın.
