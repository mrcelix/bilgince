---
baslik: "Riskli değişiklikten önce geri yükleme noktası alın"
ozet: "Sürücü veya kayıt defteri değişikliğinden önce 30 saniyelik sigorta."
konu: "windows"
etiketler: ["yedekleme", "onarim"]
yayin: 2026-06-22
populerlik: 42
---

Önce korumanın açık olduğundan emin olun:

```powershell
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "Surucu guncellemesi oncesi" -RestorePointType MODIFY_SETTINGS
```

Mevcut noktaları listelemek:

```powershell
Get-ComputerRestorePoint | Select-Object SequenceNumber, Description, CreationTime
```

Windows varsayılan olarak 24 saatte bir noktadan fazlasını oluşturmaz. Aynı gün ikinci noktayı almak isterseniz sıklık sınırını geçici olarak değiştirmeniz gerekir.

Geri yükleme noktası **yedek değildir**: kişisel dosyalarınızı geri getirmez, yalnızca sistem dosyalarını ve kayıt defterini eski hâline döndürür.
