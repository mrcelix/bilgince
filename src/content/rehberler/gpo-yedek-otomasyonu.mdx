---
baslik: "GPO yedeklerini haftalık olarak otomatikleştirin"
ozet: "Backup-GPO ile sürümlenmiş yedek, değişiklik farkı ve e-posta raporu. Bir GPO yanlışlıkla silindiğinde geri dönüş 2 dakika sürüyor."
konu: "windows-server"
etiketler: ["gpo", "zamanlanmis-gorev", "yedekleme"]
yayin: 2026-06-30
sure: 11
---

Group Policy nesneleri, Active Directory'nin yedeklenmesi en çok unutulan parçasıdır. Sistem durumu yedeği alıyor olabilirsiniz ama ondan tek bir GPO'yu geri getirmek saatler sürer.

## Haftalık yedek

```powershell
$hedef = "\\yedek01\gpo\$(Get-Date -Format 'yyyy-MM-dd')"
New-Item -ItemType Directory -Path $hedef -Force | Out-Null
Backup-GPO -All -Path $hedef -Comment "Haftalık otomatik yedek"
```

Bunu Görev Zamanlayıcı'da pazar gecesi çalışacak şekilde kurun ve **hizmet hesabıyla** çalıştırın; kendi hesabınızla kurarsanız parolanız değiştiğinde görev sessizce durur.

## Geri dönüş

```powershell
Restore-GPO -Name "Kullanici-Masaustu" -Path "\\yedek01\gpo\2026-06-29"
```

## Doğrulama adımı

Ayda bir, rastgele bir GPO'yu test ortamına geri yükleyin. Yedeğin çalıştığını yalnızca geri yükleyerek bilirsiniz — dosyanın orada durması yedek olduğu anlamına gelmez.
