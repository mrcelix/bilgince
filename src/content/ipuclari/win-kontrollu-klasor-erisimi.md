---
baslik: "Fidye yazılımına karşı kontrollü klasör erişimi"
ozet: "Belgeler klasörünü yalnızca izin verilen uygulamaların değiştirebilmesi, ücretsiz ve etkili bir katman."
konu: "windows"
etiketler: ["guvenlik", "fidye-yazilimi", "defender"]
yayin: 2026-06-28
populerlik: 35
---

```powershell
Set-MpPreference -EnableControlledFolderAccess Enabled
Add-MpPreference -ControlledFolderAccessProtectedFolders "D:\Muhasebe"
Add-MpPreference -ControlledFolderAccessAllowedApplications "C:\Program Files\Uygulama\uyg.exe"
```

Doğrudan `Enabled` yapmadan önce **denetim modunda** çalıştırın ve hangi uygulamaların engelleneceğini görün:

```powershell
Set-MpPreference -EnableControlledFolderAccess AuditMode
```

Engellenen girişimler olay günlüğünde `Microsoft-Windows-Windows Defender/Operational` altında **1123** ve **1124** kimlikleriyle görünür. Denetim modunda bu listeyi bir hafta toplayıp izin listesini oluşturun; doğrudan açmak yedekleme ve muhasebe yazılımlarını kırar.
