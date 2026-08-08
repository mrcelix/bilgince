<#
.SYNOPSIS
    "C: doldu" durumunda yeri kimin kapladığını bulur ve güvenle geri
    kazanılabilecek alanı listeler.

.DESCRIPTION
    Hiçbir şey silmez. Sırayla bakar: en büyük klasörler, Windows bileşen deposu,
    güncelleme önbelleği, geçici dosyalar, geri dönüşüm kutusu, Windows.old,
    hazırda bekletme dosyası, gölge kopyalar ve kullanıcı profilleri.

    Her kalem için "ne kadar" ve "nasıl silinir" bilgisini birlikte verir; silme
    kararını siz verirsiniz.

.PARAMETER Surucu
    Analiz edilecek sürücü. Varsayılan C:

.PARAMETER EnBuyukAdet
    Listelenecek en büyük klasör sayısı. Varsayılan 12.

.EXAMPLE
    .\disk-temizlik-analiz.ps1
    .\disk-temizlik-analiz.ps1 -Surucu D: -EnBuyukAdet 20

.NOTES
    bilgince.com — Hızlı Çözümler
#>

[CmdletBinding()]
param(
    [string]$Surucu = 'C:',
    [int]$EnBuyukAdet = 12
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

function Boyut {
    param([string]$Yol)
    if (-not (Test-Path $Yol)) { return 0 }
    (Get-ChildItem $Yol -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
}

$GB = { param($b) [math]::Round($b / 1GB, 2) }

Yaz "=== Disk analizi: $Surucu — $(Get-Date -f 'dd.MM.yyyy HH:mm') ===" Baslik

$disk = Get-PSDrive $Surucu.TrimEnd(':')
$toplam = $disk.Used + $disk.Free
Yaz ("Toplam {0} GB · Dolu {1} GB · Boş {2} GB (%{3} dolu)" -f
    (& $GB $toplam), (& $GB $disk.Used), (& $GB $disk.Free),
    [math]::Round($disk.Used / $toplam * 100)) $(if ($disk.Free / 1GB -lt 10) { 'Hata' } else { 'Bilgi' })

# ------------------------------------------------------- 1. en büyük klasörler
Yaz "`n--- 1. En büyük klasörler (kök seviye) ---" Baslik
Yaz 'Tarama sürüyor, büyük disklerde birkaç dakika alabilir…' Bilgi

Get-ChildItem "$Surucu\" -Directory -Force |
    ForEach-Object {
        [pscustomobject]@{
            Klasor = $_.FullName
            GB     = & $GB (Boyut $_.FullName)
        }
    } | Sort-Object GB -Descending | Select-Object -First $EnBuyukAdet | Format-Table -AutoSize

# ------------------------------------------------------- 2. geri kazanılabilir
Yaz "`n--- 2. Geri kazanılabilir alan ---" Baslik

$kalemler = @()

$sd = "$env:SystemRoot\SoftwareDistribution\Download"
$kalemler += [pscustomobject]@{
    Kalem = 'Windows Update indirme önbelleği'
    GB    = & $GB (Boyut $sd)
    Nasil = 'Servisi durdurup klasörü boşaltın; Windows gerekirse yeniden indirir'
}

$temp = @("$env:SystemRoot\Temp", $env:TEMP)
$tempToplam = 0
foreach ($t in $temp) { $tempToplam += Boyut $t }
$kalemler += [pscustomobject]@{
    Kalem = 'Geçici dosyalar (sistem + kullanıcı)'
    GB    = & $GB $tempToplam
    Nasil = 'Disk Temizleme ya da Ayarlar > Depolama > Geçici dosyalar'
}

$windowsOld = "$Surucu\Windows.old"
if (Test-Path $windowsOld) {
    $kalemler += [pscustomobject]@{
        Kalem = 'Windows.old (eski sürüm)'
        GB    = & $GB (Boyut $windowsOld)
        Nasil = 'Ayarlar > Depolama > Geçici dosyalar > Önceki Windows kurulumları'
    }
}

$hiber = "$Surucu\hiberfil.sys"
if (Test-Path $hiber) {
    $kalemler += [pscustomobject]@{
        Kalem = 'hiberfil.sys (hazırda bekletme)'
        GB    = & $GB (Get-Item $hiber -Force).Length
        Nasil = 'Sunucuda gereksiz: powercfg /hibernate off'
    }
}

# geri dönüşüm kutusu
$cop = (New-Object -ComObject Shell.Application).NameSpace(0xA)
$copBoyut = 0
foreach ($oge in $cop.Items()) { $copBoyut += $oge.Size }
$kalemler += [pscustomobject]@{
    Kalem = 'Geri dönüşüm kutusu'
    GB    = & $GB $copBoyut
    Nasil = 'Clear-RecycleBin -Force'
}

$kalemler | Sort-Object GB -Descending | Format-Table -AutoSize

$geri = ($kalemler | Measure-Object GB -Sum).Sum
Yaz ("Toplam kolay kazanç: yaklaşık {0} GB" -f [math]::Round($geri, 1)) $(if ($geri -gt 5) { 'Iyi' } else { 'Uyari' })

# ------------------------------------------------------------ 3. bileşen deposu
Yaz "`n--- 3. Bileşen deposu (WinSxS) ---" Baslik
Yaz 'WinSxS klasör boyutu yanıltıcıdır: içindeki dosyaların çoğu başka yerlere sabit bağdır.' Bilgi
Yaz 'Gerçek analiz için (yönetici, birkaç dakika sürer):'
Yaz '  DISM /Online /Cleanup-Image /AnalyzeComponentStore'
Yaz 'Temizleme önerilirse:'
Yaz '  DISM /Online /Cleanup-Image /StartComponentCleanup'
Yaz 'WinSxS klasörünü elle silmeyin — sistem açılmaz hâle gelir.' Uyari

# ----------------------------------------------------------- 4. gölge kopyalar
Yaz "`n--- 4. Gölge kopyalar ---" Baslik
$golge = vssadmin list shadowstorage 2>&1 | Select-String 'Used|Allocated|Maximum'
if ($golge) { $golge | ForEach-Object { Yaz "  $_" } }
else { Yaz 'Gölge kopya alanı bulunamadı ya da yönetici hakkı yok.' Bilgi }

# --------------------------------------------------------- 5. kullanıcı profilleri
Yaz "`n--- 5. Kullanıcı profilleri ---" Baslik
Get-ChildItem "$Surucu\Users" -Directory -Force |
    ForEach-Object {
        [pscustomobject]@{
            Profil     = $_.Name
            GB         = & $GB (Boyut $_.FullName)
            SonErisim  = $_.LastWriteTime.ToString('dd.MM.yyyy')
        }
    } | Sort-Object GB -Descending | Format-Table -AutoSize

Yaz "`n--- Özet ---" Baslik
Yaz 'Sıra: geri dönüşüm → geçici dosyalar → güncelleme önbelleği → Windows.old → bileşen deposu'
Yaz 'Bunlar bitince hâlâ dar geliyorsa sorun temizlik değil, kapasite planlamasıdır.' Uyari
Yaz 'Bu betik hiçbir dosyayı silmedi.'
