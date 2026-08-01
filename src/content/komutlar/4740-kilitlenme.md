---
baslik: "Hesabı kim kilitliyor?"
ozet: "PDC emulator üzerindeki son kilitlenme olaylarını hesap ve kaynak bilgisayarla listeler."
konu: "powershell"
etiketler: ["active-directory", "olay-gunlugu"]
kod: |
  Get-WinEvent -ComputerName (netdom query fsmo) -FilterHashtable @{
    LogName = 'Security'; Id = 4740
  } -MaxEvents 10 |
    Select-Object TimeCreated,
      @{ n = 'Hesap';  e = { $_.Properties[0].Value } },
      @{ n = 'Kaynak'; e = { $_.Properties[1].Value } }
dikkat: "Yalnızca PDC emulator rolündeki DC'de güvenilir sonuç verir."
ilgiliRehber: "hesap-kilitlenme-4740"
---
