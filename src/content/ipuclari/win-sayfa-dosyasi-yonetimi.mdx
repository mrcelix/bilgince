---
baslik: "Sayfa dosyasını kapatmayın, doğru yerde tutun"
ozet: "\"32 GB RAM var, pagefile'a gerek yok\" yaygın ve yanlış. Döküm alma ve bazı uygulamalar ona bağlı."
konu: "windows"
etiketler: ["performans", "bellek", "disk"]
yayin: 2026-06-14
populerlik: 50
---

Sayfa dosyasını tamamen kapatmanın iki bedeli vardır: mavi ekran sonrası **bellek dökümü alınamaz** (yani sorunu hiç çözemezsiniz) ve bazı uygulamalar ayırdıkları belleği kullanmasalar bile sayfa dosyası alanı ister.

Mevcut yapılandırmayı görmek:

```powershell
Get-CimInstance Win32_PageFileUsage |
  Select-Object Name, AllocatedBaseSize, CurrentUsage, PeakUsage
```

Sistem yönetimine bırakmak çoğu makine için doğru seçimdir:

```powershell
$cs = Get-CimInstance Win32_ComputerSystem
$cs | Set-CimInstance -Property @{ AutomaticManagedPagefile = $true }
```

Yer sıkıntısı varsa dosyayı **başka bir fiziksel diske** taşıyın; aynı diskte küçültmek performansı düşürür. C: sürücüsünde en az küçük bir çekirdek dökümü alacak kadar alan bırakın.
