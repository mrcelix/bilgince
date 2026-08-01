---
baslik: "Ağ profilini genelden özele çevirin"
ozet: "Ağ \"Genel\" olarak tanındıysa dosya paylaşımı ve uzak masaüstü sessizce engellenir."
konu: "windows"
etiketler: ["ag", "guvenlik-duvari"]
yayin: 2026-07-06
populerlik: 28
---

```powershell
Get-NetConnectionProfile
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
```

Sunucularda ve etki alanına katılmış makinelerde profil `DomainAuthenticated` olmalıdır. Etki alanı denetleyicisine ulaşamayan bir makine profili `Public`'e düşürebilir ve bu, gruplandırılmış güvenlik duvarı kurallarının tamamını devre dışı bırakır.

Sorun tekrar ediyorsa sebep genelde ağ hizmetinin, etki alanı denetleyicisi erişilebilir olmadan önce başlamasıdır; `NlaSvc` hizmetini gecikmeli başlatmaya almak çoğu vakayı çözer.
