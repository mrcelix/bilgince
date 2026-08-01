---
baslik: "Güvenli moda girmenin en hızlı yolu"
ozet: "F8 artık çalışmıyor. Shift + Yeniden Başlat ve msconfig ile iki güvenilir yöntem."
konu: "windows"
etiketler: ["onarim", "tanilama", "acilis"]
yayin: 2026-06-16
populerlik: 47
---

**Yöntem 1 — Shift + Yeniden Başlat:** Başlat menüsünde Yeniden Başlat'a **Shift** basılı tutarak tıklayın → Sorun Giderme → Gelişmiş Seçenekler → Başlangıç Ayarları → Yeniden Başlat → **4** (veya ağ için **5**).

**Yöntem 2 — msconfig:** Bir sonraki açılışın güvenli modda olmasını istiyorsanız:

```cmd
bcdedit /set {current} safeboot minimal
shutdown /r /t 0
```

Normale dönmek için — **bunu yapmayı unutmayın**, aksi hâlde makine hep güvenli modda açılır:

```cmd
bcdedit /deletevalue {current} safeboot
```

Makine hiç açılmıyorsa Windows üç başarısız açılıştan sonra kurtarma ortamını kendisi başlatır; bunu tetiklemek için açılış sırasında güç düğmesiyle iki kez kapatabilirsiniz.
