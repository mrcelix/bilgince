<#
.SYNOPSIS
    Yavaş açılan bilgisayarın sebebini ölçer.

.DESCRIPTION
    Tahmin yerine veri toplar: gerçek önyükleme süresi, açılışı yavaşlatan
    servisler ve grup ilkesi adımları, oturum açmada çalışan uygulamalar.

    Hiçbir değişiklik yapmaz — yalnızca rapor üretir.

.PARAMETER Gun
    Kaç günlük önyükleme geçmişi incelensin. Varsayılan 14.

.PARAMETER DosyayaYaz
    Raporu masaüstüne HTML olarak da kaydeder.

.EXAMPLE
    .\acilis-analiz.ps1

.EXAMPLE
    .\acilis-analiz.ps1 -Gun 30 -DosyayaYaz

.NOTES
    bilgince.com — Hızlı Çözümler. Yönetici olarak çalıştırın.
#>

[CmdletBinding()]
param(
    [ValidateRange(1, 90)][int]$Gun = 14,
    [switch]$DosyayaYaz
)

$ErrorActionPreference = 'SilentlyContinue'
$rapor = [System.Collections.Generic.List[string]]::new()

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
    $rapor.Add($Metin)
}

Yaz "=== Açılış analizi — $env:COMPUTERNAME — $(Get-Date -f 'yyyy-MM-dd HH:mm') ===" Baslik

# --------------------------------------------------- 1. gerçek önyükleme süresi
Yaz "`n--- Önyükleme süreleri (son $Gun gün) ---" Baslik

$onyukleme = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'
    Id = 100
    StartTime = (Get-Date).AddDays(-$Gun)
} | ForEach-Object {
    $x = [xml]$_.ToXml()
    $al = { param($ad) ($x.Event.EventData.Data | Where-Object Name -eq $ad).'#text' }
    [pscustomobject]@{
        Tarih       = $_.TimeCreated
        ToplamSn    = [math]::Round([int](& $al 'BootTime') / 1000, 1)
        ÇekirdekSn  = [math]::Round([int](& $al 'MainPathBootTime') / 1000, 1)
        SonrakiSn   = [math]::Round([int](& $al 'BootPostBootTime') / 1000, 1)
    }
}

if ($onyukleme) {
    $onyukleme | Sort-Object Tarih -Descending | Select-Object -First 10 | Format-Table -AutoSize | Out-String | ForEach-Object { Yaz $_ }
    $ort = [math]::Round(($onyukleme | Measure-Object ToplamSn -Average).Average, 1)
    Yaz "Ortalama açılış: $ort saniye" $(if ($ort -gt 90) { 'Uyari' } else { 'Iyi' })
    if ($ort -gt 90) {
        Yaz '90 saniyenin üzeri yavaş sayılır. Aşağıdaki bölümlere bakın.' Uyari
    }
} else {
    Yaz 'Önyükleme performans kaydı bulunamadı (günlük kapalı olabilir).' Uyari
}

# ------------------------------------------------------ 2. yavaş servis/adımlar
Yaz "`n--- Açılışı geciktiren bileşenler ---" Baslik

$gecikme = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'
    Id = 101, 102, 103, 106, 109
    StartTime = (Get-Date).AddDays(-$Gun)
} | ForEach-Object {
    $x = [xml]$_.ToXml()
    $al = { param($ad) ($x.Event.EventData.Data | Where-Object Name -eq $ad).'#text' }
    [pscustomobject]@{
        Tur     = switch ($_.Id) {
            101 { 'Uygulama' } 102 { 'Sürücü' } 103 { 'Servis' } 106 { 'Arka plan' } 109 { 'Aygıt' }
        }
        Ad      = (& $al 'Name')
        Sn      = [math]::Round([int](& $al 'TotalTime') / 1000, 1)
        Tarih   = $_.TimeCreated
    }
} | Where-Object { $_.Sn -gt 1 }

if ($gecikme) {
    $gecikme | Group-Object Ad | ForEach-Object {
        [pscustomobject]@{
            Ad       = $_.Name
            Tur      = $_.Group[0].Tur
            OrtSn    = [math]::Round(($_.Group | Measure-Object Sn -Average).Average, 1)
            Kez      = $_.Count
        }
    } | Sort-Object OrtSn -Descending | Select-Object -First 12 |
        Format-Table -AutoSize | Out-String | ForEach-Object { Yaz $_ }
} else {
    Yaz 'Belirgin gecikme kaydı yok.' Iyi
}

# ------------------------------------------------------- 3. başlangıç öğeleri
Yaz "`n--- Oturum açılışında çalışanlar ---" Baslik

$baslangic = @()
'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' | ForEach-Object {
    $anahtar = $_
    (Get-Item $anahtar).Property | ForEach-Object {
        $baslangic += [pscustomobject]@{
            Kaynak = ($anahtar -split '\\')[0]
            Ad     = $_
            Komut  = (Get-ItemProperty $anahtar -Name $_).$_
        }
    }
}

'shell:startup', 'shell:common startup' | ForEach-Object {
    $klasor = (New-Object -ComObject Shell.Application).NameSpace($_).Self.Path
    Get-ChildItem $klasor -File | ForEach-Object {
        $baslangic += [pscustomobject]@{ Kaynak = 'Başlangıç klasörü'; Ad = $_.BaseName; Komut = $_.FullName }
    }
}

Yaz "Toplam $($baslangic.Count) başlangıç öğesi:"
$baslangic | Format-Table -AutoSize | Out-String | ForEach-Object { Yaz $_ }
if ($baslangic.Count -gt 12) {
    Yaz 'On ikiden fazla başlangıç öğesi, açılışı belirgin biçimde yavaşlatır.' Uyari
}

# ------------------------------------------------------------- 4. grup ilkesi
Yaz "`n--- Grup ilkesi süreleri ---" Baslik

$gpo = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-GroupPolicy/Operational'; Id = 8001, 8002
    StartTime = (Get-Date).AddDays(-$Gun)
} | Select-Object -First 5 TimeCreated, Message

if ($gpo) {
    $gpo | ForEach-Object { Yaz ("  {0:dd.MM HH:mm} — {1}" -f $_.TimeCreated, ($_.Message -replace '\s+', ' ')) }
    Yaz 'Grup ilkesi 30 saniyeden uzun sürüyorsa yavaş bir oturum açma betiği veya eşlenmiş sürücü olabilir.' Bilgi
} else {
    Yaz 'Grup ilkesi zamanlama kaydı yok.' Bilgi
}

# ------------------------------------------------------------------- kapanış
Yaz "`n--- Sırayla bakılacaklar ---" Baslik
Yaz '1. Yukarıdaki gecikme tablosunda en üstteki üç bileşen'
Yaz '2. On ikiden fazlaysa başlangıç öğeleri'
Yaz '3. Hızlı başlatma açıksa: kapat-aç yerine yeniden başlat ile ölçün'
Yaz '4. Disk SSD değilse: gerçek çözüm donanımdır'

if ($DosyayaYaz) {
    $yol = Join-Path ([Environment]::GetFolderPath('Desktop')) "acilis-analiz-$(Get-Date -f yyyyMMdd-HHmm).txt"
    $rapor -join "`r`n" | Set-Content $yol -Encoding utf8
    Write-Host "`nRapor kaydedildi: $yol" -ForegroundColor Green
}
