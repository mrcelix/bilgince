<#
.SYNOPSIS
    Bir Windows makinesinin sertleştirme durumunu tek sayfada raporlar.

.DESCRIPTION
    Fidye yazılımı şüphesinde, devralınan bir ortamda ya da denetim öncesinde
    ilk bakılacak kalemler: SMB1, SMB imzalama, yerel yöneticiler, Defender ve
    gerçek zamanlı koruma, güvenlik duvarı profilleri, BitLocker, LAPS, PowerShell
    günlükleme, RDP açıklığı, otomatik oturum açma ve son güncelleme tarihi.

    Hiçbir ayarı değiştirmez. Her bulguyu "iyi / dikkat / kötü" olarak işaretler
    ve sonunda sayısal bir özet verir.

.PARAMETER Csv
    Sonucu nesne olarak da döndürür; filo genelinde toplamak için.

.EXAMPLE
    .\guvenlik-hizli-denetim.ps1
    .\guvenlik-hizli-denetim.ps1 -Csv | Export-Csv .\denetim.csv -NoTypeInformation -Encoding UTF8

.NOTES
    bilgince.com — Hızlı Çözümler
    Yönetici olarak çalıştırın; bazı kalemler aksi hâlde okunamaz.
#>

[CmdletBinding()]
param([switch]$Csv)

$ErrorActionPreference = 'SilentlyContinue'
$bulgular = @()

function Ekle {
    param(
        [string]$Kalem,
        [string]$Deger,
        [ValidateSet('iyi', 'dikkat', 'kotu', 'bilinmiyor')][string]$Durum,
        [string]$Not = ''
    )
    $script:bulgular += [pscustomobject]@{ Kalem = $Kalem; Deger = $Deger; Durum = $Durum; Not = $Not }
    $renk = @{ iyi = 'Green'; dikkat = 'Yellow'; kotu = 'Red'; bilinmiyor = 'Gray' }[$Durum]
    Write-Host ("  {0,-26} {1,-28} {2}" -f $Kalem, $Deger, $Not) -ForegroundColor $renk
}

Write-Host "=== Güvenlik hızlı denetimi — $env:COMPUTERNAME — $(Get-Date -f 'dd.MM.yyyy HH:mm') ===" -ForegroundColor Cyan
$yonetici = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $yonetici) { Write-Host 'UYARI: yönetici değilsiniz, bazı kalemler okunamayacak.' -ForegroundColor Yellow }

# ------------------------------------------------------------------- SMB
Write-Host "`n[SMB]" -ForegroundColor Cyan
$smb = Get-SmbServerConfiguration
Ekle 'SMB1' $(if ($smb.EnableSMB1Protocol) { 'AÇIK' } else { 'kapalı' }) `
    $(if ($smb.EnableSMB1Protocol) { 'kotu' } else { 'iyi' }) `
    $(if ($smb.EnableSMB1Protocol) { 'Fidye yazılımlarının klasik yayılma yolu' } else { '' })
Ekle 'SMB imzalama zorunlu' $(if ($smb.RequireSecuritySignature) { 'evet' } else { 'HAYIR' }) `
    $(if ($smb.RequireSecuritySignature) { 'iyi' } else { 'dikkat' }) `
    $(if (-not $smb.RequireSecuritySignature) { 'Ortadaki adam saldırısına açık' } else { '' })

# -------------------------------------------------------------- Defender
Write-Host "`n[Defender]" -ForegroundColor Cyan
$def = Get-MpComputerStatus
if ($def) {
    Ekle 'Gerçek zamanlı koruma' $(if ($def.RealTimeProtectionEnabled) { 'açık' } else { 'KAPALI' }) `
        $(if ($def.RealTimeProtectionEnabled) { 'iyi' } else { 'kotu' })
    Ekle 'Kurcalama koruması' $(if ($def.IsTamperProtected) { 'açık' } else { 'kapalı' }) `
        $(if ($def.IsTamperProtected) { 'iyi' } else { 'dikkat' })
    $imzaYas = (New-TimeSpan -Start $def.AntivirusSignatureLastUpdated).Days
    Ekle 'İmza yaşı' "$imzaYas gün" $(if ($imzaYas -le 2) { 'iyi' } elseif ($imzaYas -le 7) { 'dikkat' } else { 'kotu' })
    $taramaYas = (New-TimeSpan -Start $def.QuickScanEndTime).Days
    Ekle 'Son hızlı tarama' "$taramaYas gün önce" $(if ($taramaYas -le 7) { 'iyi' } else { 'dikkat' })
} else {
    Ekle 'Defender' 'okunamadı' 'bilinmiyor' 'Üçüncü parti antivirüs olabilir'
}

# ------------------------------------------------------------ güvenlik duvarı
Write-Host "`n[Güvenlik duvarı]" -ForegroundColor Cyan
foreach ($p in Get-NetFirewallProfile) {
    Ekle "Duvar: $($p.Name)" $(if ($p.Enabled) { 'açık' } else { 'KAPALI' }) `
        $(if ($p.Enabled) { 'iyi' } else { 'kotu' })
}

# ------------------------------------------------------------------ RDP
Write-Host "`n[Uzak masaüstü]" -ForegroundColor Cyan
$rdp = (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections).fDenyTSConnections
$nla = (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication).UserAuthentication
Ekle 'RDP' $(if ($rdp -eq 0) { 'açık' } else { 'kapalı' }) $(if ($rdp -eq 0) { 'dikkat' } else { 'iyi' })
if ($rdp -eq 0) {
    Ekle 'RDP ağ düzeyi kimlik (NLA)' $(if ($nla -eq 1) { 'açık' } else { 'KAPALI' }) `
        $(if ($nla -eq 1) { 'iyi' } else { 'kotu' })
}

# ------------------------------------------------------------- yöneticiler
Write-Host "`n[Yetkiler]" -ForegroundColor Cyan
$yoneticiler = Get-LocalGroupMember -Group 'Administrators'
Ekle 'Yerel yönetici sayısı' "$($yoneticiler.Count)" $(if ($yoneticiler.Count -le 3) { 'iyi' } else { 'dikkat' }) `
    (($yoneticiler.Name | Select-Object -First 4) -join ', ')

$laps = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\LAPS\Config' -ErrorAction SilentlyContinue
Ekle 'Windows LAPS' $(if ($laps) { 'yapılandırılmış' } else { 'yok' }) $(if ($laps) { 'iyi' } else { 'dikkat' }) `
    $(if (-not $laps) { 'Ortak yerel yönetici parolası = tek makineden tüm filoya' } else { '' })

$oto = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon
Ekle 'Otomatik oturum açma' $(if ($oto.AutoAdminLogon -eq '1') { 'AÇIK' } else { 'kapalı' }) `
    $(if ($oto.AutoAdminLogon -eq '1') { 'kotu' } else { 'iyi' }) `
    $(if ($oto.AutoAdminLogon -eq '1') { 'Parola kayıt defterinde düz metin olabilir' } else { '' })

# -------------------------------------------------------------- şifreleme
Write-Host "`n[Şifreleme]" -ForegroundColor Cyan
$bit = Get-BitLockerVolume -MountPoint $env:SystemDrive
if ($bit) {
    Ekle 'BitLocker (sistem diski)' "$($bit.VolumeStatus)" `
        $(if ($bit.ProtectionStatus -eq 'On') { 'iyi' } else { 'dikkat' })
    $anahtar = ($bit.KeyProtector | Where-Object KeyProtectorType -eq 'RecoveryPassword').Count
    Ekle 'Kurtarma anahtarı' "$anahtar adet" $(if ($anahtar -gt 0) { 'iyi' } else { 'kotu' }) `
        $(if ($anahtar -eq 0) { 'Anahtar yedeklenmemişse şifreli disk kurtarılamaz' } else { '' })
}

# ------------------------------------------------------------- günlükleme
Write-Host "`n[Günlükleme]" -ForegroundColor Cyan
$psGunluk = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Name EnableScriptBlockLogging
Ekle 'PowerShell betik günlüğü' $(if ($psGunluk.EnableScriptBlockLogging -eq 1) { 'açık' } else { 'kapalı' }) `
    $(if ($psGunluk.EnableScriptBlockLogging -eq 1) { 'iyi' } else { 'dikkat' }) `
    $(if ($psGunluk.EnableScriptBlockLogging -ne 1) { 'Olay sonrası ne çalıştığı bilinemez' } else { '' })

$guvenlikGunluk = Get-WinEvent -ListLog Security
Ekle 'Güvenlik günlüğü boyutu' "$([math]::Round($guvenlikGunluk.MaximumSizeInBytes / 1MB)) MB" `
    $(if ($guvenlikGunluk.MaximumSizeInBytes -ge 512MB) { 'iyi' } else { 'dikkat' }) `
    $(if ($guvenlikGunluk.MaximumSizeInBytes -lt 512MB) { 'Küçük günlük birkaç saatte döner, olay kaybolur' } else { '' })

# ------------------------------------------------------------- güncelleme
Write-Host "`n[Yama]" -ForegroundColor Cyan
$sonYama = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
if ($sonYama) {
    $yas = (New-TimeSpan -Start $sonYama.InstalledOn).Days
    Ekle 'Son yama' "$($sonYama.HotFixID) · $yas gün önce" `
        $(if ($yas -le 45) { 'iyi' } elseif ($yas -le 90) { 'dikkat' } else { 'kotu' })
}

# ------------------------------------------------------------------ özet
$kotu = ($bulgular | Where-Object Durum -eq 'kotu').Count
$dikkat = ($bulgular | Where-Object Durum -eq 'dikkat').Count
$iyi = ($bulgular | Where-Object Durum -eq 'iyi').Count

Write-Host "`n=== Özet ===" -ForegroundColor Cyan
Write-Host "  iyi: $iyi   dikkat: $dikkat   kötü: $kotu"
if ($kotu) {
    Write-Host "`nÖnce kapatılacaklar:" -ForegroundColor Red
    $bulgular | Where-Object Durum -eq 'kotu' | ForEach-Object { Write-Host "  • $($_.Kalem): $($_.Deger)" -ForegroundColor Red }
}
Write-Host "`nBu betik hiçbir ayarı değiştirmedi."

if ($Csv) {
    $bulgular | ForEach-Object {
        [pscustomobject]@{ Makine = $env:COMPUTERNAME; Tarih = (Get-Date -f 'yyyy-MM-dd'); Kalem = $_.Kalem; Deger = $_.Deger; Durum = $_.Durum }
    }
}
