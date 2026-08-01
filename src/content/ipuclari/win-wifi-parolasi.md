---
baslik: "Kayıtlı Wi-Fi parolasını görün"
ozet: "Makinenin bağlı olduğu ağın parolasını unuttuysanız Windows onu saklıyor."
konu: "windows"
etiketler: ["ag", "wifi"]
yayin: 2026-07-28
populerlik: 6
---

```cmd
netsh wlan show profiles
netsh wlan show profile name="AgAdi" key=clear
```

İkinci komutun çıktısındaki **Anahtar İçeriği** satırı parolayı verir. Komutu yönetici olarak çalıştırmanız gerekir.

Tüm kayıtlı ağları tek seferde dökmek için:

```powershell
(netsh wlan show profiles) -match 'All User Profile' -replace '.*: ' | ForEach-Object {
  netsh wlan show profile name="$_" key=clear | Select-String 'Key Content'
}
```
