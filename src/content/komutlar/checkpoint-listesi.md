---
baslik: "Unutulmuş checkpoint'leri bul"
ozet: "Tüm sanal makinelerdeki checkpoint'leri oluşturma tarihine göre sıralar — en eskisi en tehlikelisidir."
konu: "sanallastirma"
etiketler: ["hyper-v", "depolama"]
kod: |
  Get-VM | Get-VMSnapshot |
    Select-Object VMName, Name, CreationTime, ParentSnapshotName |
    Sort-Object CreationTime
dikkat: "Silmeye en eski checkpoint'ten başlayın; ters sırada silmek zinciri yeniden yazdırır."
ilgiliRehber: "hyperv-checkpoint-disk"
---
