---
baslik: "Uzak makinede komut çalıştırın — RDP açmadan"
ozet: "Tek bir kontrol için oturum açmak zaman kaybı. Invoke-Command aynı işi saniyeler içinde yapar."
konu: "windows"
etiketler: ["powershell", "uzaktan-yonetim"]
yayin: 2026-06-20
populerlik: 44
---

```powershell
Invoke-Command -ComputerName sunucu01, sunucu02 -ScriptBlock {
  Get-Service -Name Spooler | Select-Object MachineName, Status, StartType
}
```

Birden çok makinede aynı anda çalışır ve çıktıya makine adını ekler.

Kalıcı bir oturum açmak (art arda birkaç komut çalıştıracaksanız daha hızlıdır):

```powershell
$o = New-PSSession -ComputerName sunucu01
Invoke-Command -Session $o -ScriptBlock { Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 }
Remove-PSSession $o
```

Bağlantı kurulamazsa hedefte WinRM'i kontrol edin:

```powershell
Test-WSMan -ComputerName sunucu01
```
