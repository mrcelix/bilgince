---
baslik: "Hesap kilitlenmelerinin kaynağını 4740 olayıyla bulmak"
ozet: "Kullanıcı \"hesabım sürekli kilitleniyor\" dediğinde tahmin yürütmeyi bırakın. PDC emulator, olay filtresi ve Caller Computer Name alanı yeterli."
konu: "powershell"
etiketler: ["active-directory", "olay-gunlugu"]
yayin: 2026-07-14
sure: 8
seri: "Sıfırdan Active Directory"
seriSira: 3
---

Kilitlenen hesap, sistem yöneticisinin en çok vakit kaybettiği çağrı türüdür. Oysa kaynağı bulmak üç adım sürer.

## 1. PDC emulator'ü bulun

4740 olayı yalnızca PDC emulator rolünü tutan domain controller'da güvenilir biçimde toplanır. Diğer DC'lere bakmak zaman kaybıdır.

```powershell
netdom query fsmo
```

## 2. Son kilitlenme olaylarını çekin

```powershell
Get-WinEvent -ComputerName DC01 -FilterHashtable @{
  LogName = 'Security'; Id = 4740
} -MaxEvents 10 |
  Select-Object TimeCreated,
    @{ n = 'Hesap';  e = { $_.Properties[0].Value } },
    @{ n = 'Kaynak'; e = { $_.Properties[1].Value } }
```

## 3. Caller Computer Name alanını okuyun

`Properties[1]`, kilitlenmeyi tetikleyen istemcinin adıdır. Kaynak neredeyse her zaman şunlardan biridir:

- Eski parolayla eşlenmiş bir ağ sürücüsü
- Bir sunucuda kayıtlı, parolası değişmiş bir hizmet hesabı
- Telefonda unutulmuş bir Exchange/IMAP hesabı
- Kapatılmamış bir RDP oturumu

Kaynak makine belliyse `klist purge` ve kayıtlı kimlik bilgilerinin temizliği (`rundll32 keymgr.dll,KRShowKeyMgr`) çoğu vakayı kapatır.

## Doğrulama adımı

Temizlikten sonra aynı komutu 24 saat sonra tekrar çalıştırın. Yeni 4740 kaydı gelmiyorsa kaynak gerçekten kapanmıştır. Gelmeye devam ediyorsa kaynak makine değişmiştir — listeyi yeniden okuyun.
