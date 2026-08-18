<#
.SYNOPSIS
    Makinede kurulu yazılımların envanterini çıkarır; lisans ve güvenlik
    açısından dikkat çekenleri işaretler.

.DESCRIPTION
    Denetimden önce ya da devralınan bir ortamda ilk sorulan soru "bu makinede ne
    var" sorusudur. Kayıt defterinin üç ayrı yerine birden bakar (64-bit, 32-bit
    ve kullanıcı bazlı kurulumlar), Store uygulamalarını ayrı listeler, güncelliği
    kritik olan tarayıcı ve çalışma zamanlarını vurgular, desteği bitmiş
    sürümleri işaretler.

    Değişiklik yapmaz.

.PARAMETER Csv
    Sonucu nesne olarak döndürür; filo genelinde toplamak için.

.PARAMETER Gun
    Son kaç günde kurulanlar ayrıca listelensin. Varsayılan 30.

.EXAMPLE
    .\yazilim-envanteri.ps1
    .\yazilim-envanteri.ps1 -Csv | Export-Csv .\envanter.csv -NoTypeInformation -Encoding UTF8

.NOTES
    bilgince.com — Hızlı Çözümler
    Yalnızca ilk yola bakan envanterler eksik çıkar; bu betik üç yolun üçüne de bakar.
#>

[CmdletBinding()]
param(
    [switch]$Csv,
    [int]$Gun = 30
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

Yaz "=== Yazılım envanteri — $env:COMPUTERNAME — $(Get-Date -f 'dd.MM.yyyy') ===" Baslik

$yollar = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$kurulu = foreach ($yol in $yollar) {
    Get-ItemProperty $yol | Where-Object { $_.DisplayName -and -not $_.SystemComponent } | ForEach-Object {
        [pscustomobject]@{
            Ad          = $_.DisplayName
            Surum       = $_.DisplayVersion
            Yayinci     = $_.Publisher
            KurulumTarihi = if ($_.InstallDate -match '^\d{8}$') {
                [datetime]::ParseExact($_.InstallDate, 'yyyyMMdd', $null)
            } else { $null }
            Mimari      = if ($yol -match 'WOW6432Node') { '32-bit' } elseif ($yol -match 'HKCU') { 'kullanıcı' } else { '64-bit' }
            BoyutMB     = if ($_.EstimatedSize) { [math]::Round($_.EstimatedSize / 1024, 1) } else { $null }
        }
    }
}

$kurulu = $kurulu | Sort-Object Ad -Unique

Yaz "`n--- 1. Sayılar ---" Baslik
Yaz "Toplam: $($kurulu.Count) uygulama"
$kurulu | Group-Object Mimari | ForEach-Object { Yaz "  $($_.Name): $($_.Count)" }

$store = Get-AppxPackage | Where-Object { -not $_.IsFramework -and $_.SignatureKind -ne 'System' }
Yaz "  Store uygulaması: $($store.Count)"

# ---------------------------------------------------- 2. son kurulanlar
Yaz "`n--- 2. Son $Gun günde kurulanlar ---" Baslik
$yeni = $kurulu | Where-Object { $_.KurulumTarihi -and $_.KurulumTarihi -gt (Get-Date).AddDays(-$Gun) }
if ($yeni) {
    $yeni | Sort-Object KurulumTarihi -Descending | Select-Object Ad, Surum, KurulumTarihi, Yayinci | Format-Table -AutoSize
    Yaz 'Bilmediğiniz bir kurulum varsa kim kurdu sorusunu şimdi sorun.' Uyari
} else {
    Yaz "Son $Gun günde yeni kurulum yok." Bilgi
}

# ------------------------------------------------- 3. güncelliği kritik olanlar
Yaz "--- 3. Güncelliği kritik yazılımlar ---" Baslik
$kritik = 'Chrome', 'Firefox', 'Edge', 'Java', 'Adobe Acrobat', 'Adobe Reader', '7-Zip', 'WinRAR',
    'Notepad++', 'PuTTY', 'FileZilla', 'TeamViewer', 'AnyDesk', 'Zoom', 'VLC', 'Python', 'Node.js'
$bulunanKritik = $kurulu | Where-Object { $ad = $_.Ad; $kritik | Where-Object { $ad -like "*$_*" } }
if ($bulunanKritik) {
    $bulunanKritik | Select-Object Ad, Surum, Mimari | Format-Table -AutoSize
    Yaz 'Bunlar Windows Update kapsamında değildir; winget ya da dağıtım aracıyla ayrıca güncellenmeli.' Uyari
    Yaz '  winget upgrade --all --include-unknown' Bilgi
}

# ------------------------------------------------------- 4. dikkat çekenler
Yaz "`n--- 4. Dikkat çekenler ---" Baslik
$riskli = @(
    @{ Desen = 'Java*'; Not = 'Oracle Java ticari kullanımda lisans ister; OpenJDK''ya geçilip geçilmediğini kontrol edin.' }
    @{ Desen = '*TeamViewer*'; Not = 'Uzak erişim aracı: kurumsal lisans ve erişim denetimi gözden geçirilmeli.' }
    @{ Desen = '*AnyDesk*'; Not = 'Uzak erişim aracı: fidye yazılımı olaylarında sık kullanılıyor, kimin kurduğu bilinmeli.' }
    @{ Desen = '*WinRAR*'; Not = 'Deneme süresi biten kurulumlar lisanssız kullanım sayılır.' }
    @{ Desen = '*uTorrent*'; Not = 'Kurumsal makinede bulunmamalı.' }
    @{ Desen = '*Toolbar*'; Not = 'İstenmeyen yazılım göstergesi.' }
    @{ Desen = '*2010*'; Not = 'Desteği bitmiş sürüm olabilir — güvenlik yaması almıyor.' }
    @{ Desen = '*2013*'; Not = 'Desteği bitmiş sürüm olabilir — güvenlik yaması almıyor.' }
)
$bulgu = 0
foreach ($r in $riskli) {
    foreach ($u in $kurulu | Where-Object Ad -like $r.Desen) {
        Yaz "  $($u.Ad) $($u.Surum)" Uyari
        Yaz "    $($r.Not)" Bilgi
        $bulgu++
    }
}
if (-not $bulgu) { Yaz '  Dikkat çeken kurulum bulunamadı.' Iyi }

# --------------------------------------------------------- 5. tam liste
Yaz "`n--- 5. Tam liste ---" Baslik
$kurulu | Sort-Object Ad | Select-Object Ad, Surum, Yayinci, Mimari | Format-Table -AutoSize

Yaz "`n--- Envantere eklenecek sütun ---" Baslik
Yaz 'Bu listeye "lisans modeli" sütunu ekleyin: ücretsiz / kurumsal lisanslı / kişisel lisanslı.'
Yaz 'Denetimde sorulan soru "ne kurulu" değil, "hangi hakla kurulu" sorusudur.'

if ($Csv) {
    $kurulu | ForEach-Object {
        [pscustomobject]@{
            Makine = $env:COMPUTERNAME; Tarih = (Get-Date -f 'yyyy-MM-dd')
            Ad = $_.Ad; Surum = $_.Surum; Yayinci = $_.Yayinci; Mimari = $_.Mimari
        }
    }
}
