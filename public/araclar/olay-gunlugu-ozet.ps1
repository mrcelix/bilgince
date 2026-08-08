<#
.SYNOPSIS
    Olay günlüklerinin son N saatini gruplayıp okunur bir özet çıkarır; bilinen
    kritik olay kimliklerini açıklamasıyla birlikte gösterir.

.DESCRIPTION
    Olay görüntüleyicide binlerce satır arasında kaybolmak yerine: hangi olay
    kaç kez tekrarladı, ilk ne zaman başladı, ne anlama geliyor. Sistem,
    Uygulama ve Güvenlik günlüklerini birlikte tarar; sahada anlamı olan
    kimlikler için Türkçe açıklama ve sonraki adım verir.

    Değişiklik yapmaz.

.PARAMETER Saat
    Kaç saat geriye bakılacağı. Varsayılan 24.

.PARAMETER Gunluk
    Taranacak günlükler. Varsayılan System, Application.

.PARAMETER Dosya
    Özeti metin dosyasına da yazar.

.EXAMPLE
    .\olay-gunlugu-ozet.ps1
    .\olay-gunlugu-ozet.ps1 -Saat 72 -Gunluk System,Application,Security

.NOTES
    bilgince.com — Hızlı Çözümler
    Güvenlik günlüğü için yönetici hakkı gerekir.
#>

[CmdletBinding()]
param(
    [int]$Saat = 24,
    [string[]]$Gunluk = @('System', 'Application'),
    [string]$Dosya
)

$ErrorActionPreference = 'SilentlyContinue'
$rapor = [System.Collections.Generic.List[string]]::new()

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
    $rapor.Add($Metin)
}

# Sahada anlamı olan kimlikler — sözlük tarafı
$SOZLUK = @{
    6008  = 'Beklenmedik kapanma — 41 ve 1001 ile birlikte okuyun'
    41    = 'Kernel-Power: makine temiz kapanmadı (güç, donanım ya da kilitlenme)'
    1074  = 'Kapatma/yeniden başlatma başlatıldı — kim ve neden olayın içinde'
    1001  = 'BugCheck (mavi ekran) — durdurma kodu ve döküm yolu olayın içinde'
    7045  = 'Yeni hizmet kuruldu — beklenmedikse kalıcılık göstergesi olabilir'
    7034  = 'Hizmet beklenmedik biçimde sonlandı'
    7031  = 'Hizmet çöktü, kurtarma devrede — sorunu maskeliyor olabilir'
    7000  = 'Hizmet başlatılamadı'
    55    = 'NTFS yapısı bozuk — chkdsk planlayın, önce yedeği doğrulayın'
    51    = 'Sayfalama işleminde disk hatası — veri kaybı riski'
    153   = 'Disk G/Ç isteği yeniden denendi — yol ya da disk sorunu'
    129   = 'Depolama denetleyicisi sıfırlandı'
    2019  = 'Sayfalanmayan havuz tükendi — sürücü sızıntısı, poolmon ile bakın'
    5719  = 'Netlogon: etki alanı denetleyicisi bulunamadı'
    5722  = 'Makine hesabı kimlik doğrulaması başarısız — güvenli kanal bozuk'
    1058  = 'Grup ilkesi dosyası okunamadı (SYSVOL/DFS)'
    1129  = 'Ağ hazır değilken ilke işlendi'
    1000  = 'Uygulama çökmesi — hatalı modül adı olayın içinde'
    1026  = '.NET çalışma zamanı hatası'
    10016 = 'DCOM izin uyarısı — genelde gürültü'
    36871 = 'Schannel: TLS kimlik bilgisi oluşturulamadı'
    36888 = 'Schannel önemli hata — sertifika ya da şifre paketi'
    4740  = 'Hesap kilitlendi'
    4625  = 'Oturum açma başarısız'
    1102  = 'GÜVENLİK GÜNLÜĞÜ TEMİZLENDİ — meşru sebebi neredeyse yoktur'
    219   = 'Sürücü yüklenemedi'
}

$baslangic = (Get-Date).AddHours(-$Saat)
Yaz "=== Olay özeti — $env:COMPUTERNAME — son $Saat saat ===" Baslik
Yaz "Başlangıç: $($baslangic.ToString('dd.MM.yyyy HH:mm'))"

$tumOlaylar = @()
foreach ($g in $Gunluk) {
    $olaylar = Get-WinEvent -FilterHashtable @{ LogName = $g; Level = 1, 2, 3; StartTime = $baslangic } -ErrorAction SilentlyContinue
    if ($olaylar) {
        $tumOlaylar += $olaylar
        Yaz "`n$g : $($olaylar.Count) kritik/hata/uyarı olayı"
    } else {
        Yaz "`n$g : olay yok ya da okunamadı" Bilgi
    }
}

if (-not $tumOlaylar) {
    Yaz "`nBelirtilen aralıkta olay bulunamadı." Iyi
    return
}

# ------------------------------------------------------------- gruplama
Yaz "`n--- En sık tekrarlayanlar ---" Baslik
$gruplar = $tumOlaylar | Group-Object Id | Sort-Object Count -Descending

foreach ($g in $gruplar | Select-Object -First 15) {
    $ilk = $g.Group | Sort-Object TimeCreated | Select-Object -First 1
    $son = $g.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1
    $kimlik = [int]$g.Name
    $aciklama = $SOZLUK[$kimlik]
    $seviye = ($g.Group | Sort-Object Level | Select-Object -First 1).LevelDisplayName

    $tur = if ($kimlik -in 1102, 51, 55, 2019, 1001) { 'Hata' }
           elseif ($aciklama) { 'Uyari' } else { 'Bilgi' }

    Yaz ("`n[{0}] {1,5} kez · {2} · {3}" -f $kimlik, $g.Count, $seviye, $son.ProviderName) $tur
    if ($aciklama) { Yaz "  → $aciklama" $tur }
    Yaz ("  ilk: {0}   son: {1}" -f $ilk.TimeCreated.ToString('dd.MM HH:mm'), $son.TimeCreated.ToString('dd.MM HH:mm'))
    Yaz ("  örnek: {0}" -f (($son.Message -split "`n")[0]).Trim())
}

# ------------------------------------------------------- zaman dağılımı
Yaz "`n--- Saat dağılımı ---" Baslik
$saatler = $tumOlaylar | Group-Object { $_.TimeCreated.ToString('dd.MM HH') } | Sort-Object Name
$enYuksek = ($saatler | Measure-Object Count -Maximum).Maximum
foreach ($s in $saatler | Select-Object -Last 24) {
    $cubuk = '█' * [math]::Max(1, [math]::Round($s.Count / $enYuksek * 40))
    Yaz ("  {0}  {1,4}  {2}" -f $s.Name, $s.Count, $cubuk)
}
Yaz 'Belirli bir saatte yığılma varsa sebep genelde zamanlanmış bir iştir; sürekli akış donanım ya da sürücüdür.' Bilgi

# ------------------------------------------------------------ öne çıkanlar
Yaz "`n--- Öncelikli bakılacaklar ---" Baslik
$oncelikli = $gruplar | Where-Object { [int]$_.Name -in $SOZLUK.Keys -and [int]$_.Name -in 1102, 51, 55, 2019, 1001, 6008, 41, 7045, 5722 }
if ($oncelikli) {
    foreach ($o in $oncelikli) {
        Yaz "  • $($o.Name) ($($o.Count) kez): $($SOZLUK[[int]$o.Name])" Hata
    }
} else {
    Yaz '  Kritik listedeki kimliklerden hiçbiri görünmedi.' Iyi
}

if ($Dosya) {
    $rapor -join "`r`n" | Out-File -FilePath $Dosya -Encoding utf8
    Write-Host "`nÖzet kaydedildi: $Dosya" -ForegroundColor Green
}

Write-Host "`nKimliklerin ayrıntılı açıklaması: https://www.bilgince.com/araclar/olay-kimligi" -ForegroundColor Gray
