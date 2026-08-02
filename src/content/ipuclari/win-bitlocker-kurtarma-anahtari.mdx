---
baslik: "BitLocker kurtarma anahtarı nerede duruyor?"
ozet: "Kurtarma ekranı karşınıza çıktığında aramaya başlamak çok geç. Anahtarın nerede olduğunu önceden doğrulayın."
konu: "windows"
etiketler: ["bitlocker", "guvenlik", "sifreleme"]
yayin: 2026-07-26
populerlik: 9
---

Anahtar üç yerden birinde olabilir: Microsoft/Entra hesabı, Active Directory ya da yazdırılmış bir dosya.

Makinede durumu ve koruyucuları görmek için:

```powershell
Get-BitLockerVolume -MountPoint C: |
  Select-Object MountPoint, VolumeStatus, ProtectionStatus, KeyProtector
```

Anahtarı Entra ID'ye yedeklemek:

```powershell
$v = Get-BitLockerVolume -MountPoint C:
$id = ($v.KeyProtector | Where-Object KeyProtectorType -eq 'RecoveryPassword').KeyProtectorId
BackupToAAD-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $id
```

Şirket cihazlarında bu yedeklemenin **politikayla zorunlu** olduğundan emin olun; kullanıcıya bırakılan yedekleme yapılmaz.
