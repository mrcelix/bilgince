---
baslik: "Pasif AD hesaplarını 10 satırda raporlayın"
ozet: "90 gündür giriş yapmayan hesapları listeleyin, CSV'ye dökün ve güvenle devre dışı bırakın. Bu rehber, tek başına LastLogonDate'e güvenmenin neden hataya açık olduğunu da gösteriyor."
seoBaslik: "PowerShell ile pasif AD hesaplarını raporlama"
konu: "powershell"
etiketler: ["active-directory", "raporlama", "csv"]
yayin: 2026-07-28
guncelleme: 2026-08-09
sure: 14
seri: "Sıfırdan Active Directory"
seriSira: 4
oneCikan: true
---

Her Active Directory ortamında, işten ayrılmış ama hesabı hâlâ açık duran kullanıcılar birikir. Bunlar yalnızca lisans israfı değil; saldırı yüzeyinin en sessiz parçasıdır. Aşağıdaki tek komut zinciri, 90 gündür giriş yapmamış aktif hesapları bulup denetlenebilir bir CSV'ye döker.

## Neden LastLogonDate tek başına yetmez

**LastLogonDate**, `lastLogonTimestamp` özniteliğinden türetilir ve bu öznitelik domain controller'lar arasında **9 ila 14 günlük bir gecikmeyle** eşitlenir. Yani dün giriş yapmış bir kullanıcı, raporda iki hafta önce girmiş gibi görünebilir. Sınırı 90 gün seçmemizin sebebi tam olarak budur: eşitleme gecikmesi bu aralıkta gürültü yaratmaz.

Gerçek zamanlı doğruluk gerekiyorsa `lastLogon` özniteliğine bakmanız gerekir — ama o da eşitlenmez, her DC kendi değerini tutar. Yani tüm DC'leri tek tek sorgulayıp en büyüğünü almanız gerekir. Çoğu senaryoda buna gerek yoktur.

## Komut

```powershell
# 90 gündür giriş yapmayan, hâlâ etkin hesaplar
$sinir = (Get-Date).AddDays(-90)

Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly |
  Get-ADUser -Properties LastLogonDate, whenCreated, Enabled |
  Where-Object { $_.Enabled -and $_.whenCreated -lt $sinir } |
  Select-Object Name, SamAccountName, LastLogonDate, whenCreated |
  Sort-Object LastLogonDate |
  Export-Csv '.\pasif-hesaplar.csv' -NoTypeInformation -Encoding UTF8
```

`whenCreated` kontrolü kritik: yeni açılmış ama henüz hiç giriş yapılmamış hesaplar aksi hâlde listeye düşer ve stajyerin ilk gününde hesabını kapatmış olursunuz.

`-Encoding UTF8` de öyle: Türkçe adları olan hesaplar aksi hâlde Excel'de bozuk görünür.

## Devre dışı bırakmadan önce doğrulama

Listeyi doğrudan uygulamayın. Üç adımlık şu kontrol, geri dönüşü olmayan hataları engelliyor:

1. **Hizmet hesaplarını ayıklayın.** `svc-`, `sa-` gibi öneklerle başlayan hesaplar interaktif giriş yapmaz; pasif görünmeleri normaldir.
2. **İK listesiyle çapraz kontrol edin.** Uzun süreli izin, doğum izni ve askerlik durumundaki kullanıcılar bu raporda çıkar.
3. **Silmeden önce devre dışı bırakın** ve 30 gün "Karantina" OU'sunda bekletin. Silme işlemi geri alınamaz; devre dışı bırakma tek tıkla geri alınır.

Karantinaya taşıma da tek satır:

```powershell
Import-Csv '.\pasif-hesaplar.csv' | ForEach-Object {
  Disable-ADAccount -Identity $_.SamAccountName
  Move-ADObject -Identity (Get-ADUser $_.SamAccountName).DistinguishedName `
    -TargetPath 'OU=Karantina,DC=sirket,DC=local'
}
```

## Doğrulama adımı

Komutu çalıştırdıktan sonra `(Import-Csv .\pasif-hesaplar.csv).Count` ile satır sayısını kontrol edin. Toplam kullanıcı sayınızın %20'sinden fazlaysa filtre yanlış kurulmuştur — büyük olasılıkla `-UsersOnly` parametresi atlanmış ve bilgisayar hesapları da listeye girmiştir.

Sayı makulse raporu İK ile paylaşın ve onay bekleyin. Bu adımı atlayıp doğrudan uygulamak, bu işin bilinen tek geri dönülemez hatasıdır.
