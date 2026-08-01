---
baslik: "telnet yerine Test-NetConnection"
ozet: "Port açık mı diye bakmak için istemci özelliği kurmanıza gerek yok; PowerShell zaten yapıyor."
konu: "ag"
etiketler: ["tanilama", "port"]
yayin: 2026-07-18
sure: 2
populerlik: 14
---

Bir portun açık olup olmadığını görmek için Telnet İstemcisi kurmayı bırakın. PowerShell aynı işi yapar, üstelik yönlendirme ve DNS bilgisini de verir.

```powershell
Test-NetConnection sunucu01 -Port 443 -InformationLevel Detailed
```

Çıktıdaki `TcpTestSucceeded` alanı `True` ise port açıktır. `PingSucceeded` `False` olsa bile bu geçerlidir — çoğu güvenlik duvarı ICMP'yi kapatır ama TCP'ye izin verir.
