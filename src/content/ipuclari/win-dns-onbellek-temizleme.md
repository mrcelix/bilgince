---
baslik: "DNS önbelleğini temizleyin"
ozet: "Kayıt değişti ama makine hâlâ eski adrese gidiyorsa önce önbelleğe bakın."
konu: "windows"
etiketler: ["ag", "dns", "tanilama"]
yayin: 2026-07-30
populerlik: 5
---

```powershell
Clear-DnsClientCache      # veya: ipconfig /flushdns
Get-DnsClientCache | Where-Object Entry -like "*sirket.local*"
```

İkinci komut, temizlemeden önce önbellekte ne olduğunu gösterir — sorunun gerçekten önbellekte olup olmadığını böyle anlarsınız. Temizledikten sonra da eski adres dönüyorsa sorun DNS sunucusundadır, istemcide değil.
