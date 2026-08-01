---
baslik: "Sorunlu sürücüyü kaldırın, eskisini geri yükleyin"
ozet: "pnputil ile sürücü deposunu listeleyin ve hatalı paketi temiz şekilde kaldırın."
konu: "windows"
etiketler: ["surucu", "onarim", "donanim"]
yayin: 2026-06-26
populerlik: 37
---

Yüklü üçüncü taraf sürücüleri listelemek:

```cmd
pnputil /enum-drivers
```

Çıktıdaki `oem##.inf` adını not edin ve kaldırın:

```cmd
pnputil /delete-driver oem42.inf /uninstall /force
```

Belirli bir sürücüyü yüklemek:

```cmd
pnputil /add-driver "D:\surucu\net.inf" /install
```

Sorunun sürücüden geldiğinden emin değilseniz önce Aygıt Yöneticisi'nde **Sürücüyü Geri Al** deneyin — kaldırmaktan daha güvenlidir ve bir önceki sürüme döner.
