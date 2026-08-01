---
baslik: "Tüm GPO'ları tarihli klasöre yedekle"
ozet: "Görev Zamanlayıcı ile haftalık çalıştırmak için tasarlanmış, sürümlenmiş GPO yedeği."
konu: "windows-server"
etiketler: ["gpo", "yedekleme"]
kod: |
  $hedef = "\\yedek01\gpo\$(Get-Date -Format 'yyyy-MM-dd')"
  New-Item -ItemType Directory -Path $hedef -Force | Out-Null
  Backup-GPO -All -Path $hedef -Comment "Haftalık otomatik yedek"
dikkat: "Görevi kendi hesabınızla değil hizmet hesabıyla kurun; parolanız değişince görev sessizce durur."
ilgiliRehber: "gpo-yedek-otomasyonu"
---
