<#
.SYNOPSIS
    Teams (yeni ve klasik istemci) önbelleğini analiz eder, istenirse sıfırlar.

.DESCRIPTION
    Teams'te "cihaz listede yok", "görüntü siyah", "toplantıya girilmiyor" gibi
    belirtilerin bir kısmı bozuk yerel önbellekten gelir. Bu betik önce hangi
    istemcinin kurulu olduğunu, önbelleğin nerede ve ne kadar yer tuttuğunu
    raporlar.

    -Sifirla verildiğinde Teams kapatılır ve önbellek klasörleri yeniden
    adlandırılır (silinmez). Oturum açma bilgisi korunur; sohbet geçmişi zaten
    sunucudadır, kaybolmaz.

.PARAMETER Sifirla
    Önbellek klasörlerini yeniden adlandırarak sıfırlar.

.EXAMPLE
    .\teams-onbellek-sifirla.ps1
    .\teams-onbellek-sifirla.ps1 -Sifirla

.NOTES
    bilgince.com — Hızlı Çözümler
    Kullanıcının kendi oturumunda çalıştırın.
#>

[CmdletBinding()]
param(
    [switch]$Sifirla
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

function BoyutMB {
    param([string]$Yol)
    if (-not (Test-Path $Yol)) { return $null }
    [math]::Round(((Get-ChildItem $Yol -Recurse -File -Force -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum).Sum) / 1MB, 1)
}

Yaz "=== Teams önbellek durumu — $env:USERNAME ===" Baslik

# ------------------------------------------------------------- 1. istemciler
Yaz "`n--- 1. Kurulu istemciler ---" Baslik
$yeni = Get-AppxPackage -Name 'MSTeams' -ErrorAction SilentlyContinue
$klasikYol = "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"

if ($yeni) { Yaz "  Yeni Teams (MSTeams) — sürüm $($yeni.Version)" Iyi }
else { Yaz '  Yeni Teams kurulu değil' Bilgi }

if (Test-Path $klasikYol) { Yaz '  Klasik Teams (Electron) kurulu' Uyari }
else { Yaz '  Klasik Teams kurulu değil' Bilgi }

if (-not $yeni -and -not (Test-Path $klasikYol)) {
    Yaz 'Hiçbir Teams istemcisi bulunamadı.' Hata
    return
}

# --------------------------------------------------------------- 2. önbellek
Yaz "`n--- 2. Önbellek klasörleri ---" Baslik

$hedefler = @()
if ($yeni) {
    $hedefler += "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache"
    $hedefler += "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalState"
}
if (Test-Path $klasikYol) {
    foreach ($alt in 'Cache', 'blob_storage', 'databases', 'GPUCache', 'IndexedDB', 'Local Storage', 'tmp') {
        $hedefler += "$env:APPDATA\Microsoft\Teams\$alt"
    }
}

$tablo = foreach ($h in $hedefler) {
    $mb = BoyutMB $h
    if ($null -ne $mb) { [pscustomobject]@{ Klasor = $h.Replace($env:USERPROFILE, '~'); MB = $mb } }
}
if ($tablo) { $tablo | Sort-Object MB -Descending | Format-Table -AutoSize }
$toplam = ($tablo | Measure-Object MB -Sum).Sum
Yaz ("Toplam önbellek: {0} MB" -f [math]::Round($toplam, 1))
if ($toplam -gt 3000) {
    Yaz '3 GB üstü önbellek olağan değildir; sıfırlamak hem yer açar hem tuhaf davranışları giderir.' Uyari
}

# ------------------------------------------------------- 3. cihaz izinleri (sık sebep)
Yaz "`n--- 3. Kamera ve mikrofon izinleri ---" Baslik
foreach ($cihaz in 'webcam', 'microphone') {
    $yol = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$cihaz"
    $genel = (Get-ItemProperty $yol -Name Value -ErrorAction SilentlyContinue).Value
    Yaz ("  {0,-12} genel: {1}" -f $cihaz, ($genel ?? 'tanımsız')) $(if ($genel -eq 'Deny') { 'Hata' } else { 'Iyi' })
    $masaustu = (Get-ItemProperty "$yol\NonPackaged" -Name Value -ErrorAction SilentlyContinue).Value
    if ($masaustu) {
        Yaz ("  {0,-12} masaüstü uygulamaları: {1}" -f '', $masaustu) $(if ($masaustu -eq 'Deny') { 'Hata' } else { 'Iyi' })
    }
}
Yaz 'Deny görüyorsanız önbellek sıfırlamanın faydası olmaz; önce izni açın.' Bilgi

# ----------------------------------------------------------------- sıfırlama
if (-not $Sifirla) {
    Yaz "`n--- Sonraki adım ---" Baslik
    Yaz 'Bu çalıştırma hiçbir şey değiştirmedi.'
    Yaz 'Önbelleği sıfırlamak için:  .\teams-onbellek-sifirla.ps1 -Sifirla'
    Yaz 'Sohbet geçmişi sunucuda durur, kaybolmaz. Yalnızca yerel önbellek yeniden kurulur.'
    return
}

Yaz "`n--- Sıfırlama ---" Baslik
Get-Process -Name 'ms-teams', 'Teams' -ErrorAction SilentlyContinue | ForEach-Object {
    Yaz "  kapatılıyor: $($_.ProcessName) (PID $($_.Id))"
    $_ | Stop-Process -Force
}
Start-Sleep -Seconds 3

$damga = Get-Date -f 'yyyyMMdd-HHmmss'
$sayac = 0
foreach ($h in $hedefler) {
    if (Test-Path $h) {
        $yeniAd = "$h.eski-$damga"
        Rename-Item $h $yeniAd -ErrorAction SilentlyContinue
        if (Test-Path $yeniAd) { Yaz "  yeniden adlandırıldı: $($h.Replace($env:USERPROFILE,'~'))" Iyi; $sayac++ }
        else { Yaz "  atlandı (kilitli): $($h.Replace($env:USERPROFILE,'~'))" Uyari }
    }
}

Yaz "`n$sayac klasör sıfırlandı. Teams'i açın; ilk açılış yavaş olur, önbellek yeniden kurulur." Iyi
Yaz "Eski klasörler *.eski-$damga adıyla duruyor; sorun çıkmazsa bir hafta sonra silin."
