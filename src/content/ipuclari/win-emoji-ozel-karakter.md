---
baslik: "Emoji ve özel karakterleri klavyeden yazın"
ozet: "Win + nokta, her metin kutusunda emoji, sembol ve özel karakter panelini açar."
konu: "windows"
etiketler: ["kisayol", "verimlilik"]
yayin: 2026-06-14
populerlik: 49
---

**Win + .** (veya Win + ;) emoji panelini açar. Panelde yalnızca emoji yok: üst sekmelerde **semboller**, **kaomoji** ve **son kullanılanlar** var.

Semboller sekmesi, belge yazarken en çok işe yarayan kısımdır: ± × ÷ ≈ ° ™ § → ✓ gibi karakterler için karakter eşlemi açmaya gerek kalmaz.

Panel açılmıyorsa dokunmatik klavye hizmeti kapalı olabilir:

```powershell
Get-Service TabletInputService | Select-Object Status, StartType
```
