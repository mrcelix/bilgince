---
baslik: "Hyper-V checkpoint'leri diski neden sessizce doldurur?"
ozet: "Bir gecede 400 GB kaybeden bir host'un anatomisi ve avhd zincirini güvenle birleştirmenin doğru sırası."
konu: "sanallastirma"
etiketler: ["hyper-v", "depolama"]
yayin: 2026-07-21
sure: 16
oneCikan: false
---

Checkpoint aldığınızda Hyper-V sanal diski dondurur ve tüm yeni yazmaları `.avhdx` adında bir fark diskine yönlendirir. Sorun şu: bu dosya, silinene kadar büyümeye devam eder ve kimse ona bakmaz.

## Zincir nasıl oluşur

Her checkpoint bir halka ekler. Üç checkpoint alınmış bir makinede disk okuması artık dört dosyayı dolaşır: temel `.vhdx` ve üç `.avhdx`. Performans düşer, alan tükenir.

```powershell
Get-VM | Get-VMSnapshot |
  Select-Object VMName, Name, CreationTime, ParentSnapshotName |
  Sort-Object CreationTime
```

## Birleştirmenin doğru sırası

1. Sanal makineyi **kapatın**. Çalışırken birleştirme mümkündür ama I/O yükü altında saatler sürer.
2. Host'ta **checkpoint boyutu kadar** boş alan olduğunu doğrulayın.
3. En **eski** checkpoint'ten başlayarak silin. Ters sırada silmek zinciri yeniden yazdırır.
4. `Get-VM | Select-Object Name, Status` ile "Merging disks" durumunun bittiğini bekleyin.

## Doğrulama adımı

Birleştirme bittikten sonra sanal makinenin klasöründe hiç `.avhdx` kalmamalı. Kalıyorsa birleştirme yarıda kesilmiştir; makineyi açmadan önce `Merge-VHD` ile elle tamamlayın — açarsanız zincir yeniden dallanır.
