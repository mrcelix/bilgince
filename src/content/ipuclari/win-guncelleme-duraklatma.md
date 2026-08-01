---
baslik: "Güncellemeyi kritik hafta boyunca duraklatın"
ozet: "Envanter veya yıl sonu kapanışında yeniden başlatma istemiyorsanız duraklatma doğru araçtır — kapatma değil."
konu: "windows"
etiketler: ["guncelleme", "bakim"]
yayin: 2026-06-26
populerlik: 38
---

**Ayarlar → Windows Update → Güncellemeleri duraklat** ile en fazla 5 hafta erteleyebilirsiniz.

Kurumsal ortamda etkin saatleri ve yeniden başlatma davranışını politikayla yönetin; kullanıcıya bırakmayın. Etkin saatleri betikle ayarlamak:

```powershell
$p = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
Set-ItemProperty $p -Name ActiveHoursStart -Value 8
Set-ItemProperty $p -Name ActiveHoursEnd   -Value 19
```

Güncelleme hizmetini tamamen devre dışı bırakmayın: makine yalnızca yeniden başlatmayı değil, güvenlik yamalarını da almayı bırakır ve bunu aylarca kimse fark etmez.

Bekleyen yeniden başlatma olup olmadığını kontrol etmek:

```powershell
Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
```
