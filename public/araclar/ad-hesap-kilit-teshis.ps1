<#
.SYNOPSIS
    Sürekli kilitlenen Active Directory hesabının kilidi nereden yediğini bulur.

.DESCRIPTION
    Kilitlenme belirtidir; sebep neredeyse her zaman eski parolayı tekrar tekrar
    deneyen bir şeydir. Bu betik sırayla şunlara bakar:
      1. Hesabın kilit durumu ve son kötü parola denemesi
      2. PDC öykünücüsündeki 4740 olayları — kilidi hangi makine tetikledi
      3. Kaynak makinede eski parolayı saklayan yerler: kimlik deposu,
         zamanlanmış görevler, servisler, eşlenmiş sürücüler

    Hiçbir şey değiştirmez. Kilidi açmak için -KilidiAc kullanın.

.PARAMETER Kullanici
    Örnek: ahmet.yilmaz

.PARAMETER Saat
    Kaç saat geriye bakılacağı. Varsayılan 24.

.PARAMETER KilidiAc
    Teşhisten sonra hesabın kilidini açar (yetki gerekir).

.EXAMPLE
    .\ad-hesap-kilit-teshis.ps1 -Kullanici ahmet.yilmaz
    .\ad-hesap-kilit-teshis.ps1 -Kullanici ahmet.yilmaz -Saat 72

.NOTES
    bilgince.com — Hızlı Çözümler
    ActiveDirectory modülü gerekir (RSAT). 4740 olayları yalnızca PDC
    öykünücüsünde toplanır; betik onu kendisi bulur.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Kullanici,
    [int]$Saat = 24,
    [switch]$KilidiAc
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Yaz 'ActiveDirectory modülü yok. RSAT kurun ya da betiği bir etki alanı denetleyicisinde çalıştırın.' Hata
    return
}
Import-Module ActiveDirectory

Yaz "=== Hesap kilitlenme teşhisi: $Kullanici ===" Baslik

# ----------------------------------------------------------- 1. hesap durumu
Yaz "`n--- 1. Hesap durumu ---" Baslik
$hesap = Get-ADUser $Kullanici -Properties LockedOut, badPwdCount, LastBadPasswordAttempt,
    PasswordLastSet, PasswordExpired, Enabled, lockoutTime

if (-not $hesap) {
    Yaz "Kullanıcı bulunamadı: $Kullanici" Hata
    return
}

$hesap | Select-Object SamAccountName, Enabled, LockedOut, badPwdCount,
    LastBadPasswordAttempt, PasswordLastSet, PasswordExpired | Format-List

if ($hesap.LockedOut) { Yaz 'Hesap ŞU AN KİLİTLİ.' Hata }
else { Yaz 'Hesap şu an kilitli değil — kilit açılmış ya da henüz eşiğe ulaşılmamış olabilir.' Uyari }

# ilke: eşik ve pencere bilinmeden "neden bu kadar sık" sorusu cevaplanamaz
$ilke = Get-ADDefaultDomainPasswordPolicy
Yaz "`nKilit ilkesi: $($ilke.LockoutThreshold) hatalı denemede kilit, $($ilke.LockoutObservationWindow.TotalMinutes) dakikalık pencere, $($ilke.LockoutDuration.TotalMinutes) dakika kilitli kalır."

# ------------------------------------------------------------- 2. 4740 olayı
Yaz "`n--- 2. Kilidi tetikleyen makineler (4740) ---" Baslik
$pdc = (Get-ADDomain).PDCEmulator
Yaz "PDC öykünücüsü: $pdc"

$olaylar = Get-WinEvent -ComputerName $pdc -FilterHashtable @{
    LogName   = 'Security'
    Id        = 4740
    StartTime = (Get-Date).AddHours(-$Saat)
} -ErrorAction SilentlyContinue

$benimkiler = $olaylar | Where-Object { $_.Properties[0].Value -eq $hesap.SamAccountName }

if (-not $benimkiler) {
    Yaz "Son $Saat saatte bu hesap için 4740 olayı yok." Uyari
    Yaz 'Denetim ilkesi kapalı olabilir: "Audit Account Management" başarı denetimi açık olmalı.' Bilgi
} else {
    $benimkiler | ForEach-Object {
        [pscustomobject]@{
            Zaman        = $_.TimeCreated
            KaynakMakine = $_.Properties[1].Value
        }
    } | Sort-Object Zaman -Descending | Format-Table -AutoSize

    $sik = $benimkiler | Group-Object { $_.Properties[1].Value } | Sort-Object Count -Descending
    Yaz "En sık tetikleyen: $($sik[0].Name) — $($sik[0].Count) kez" Hata
    $kaynak = $sik[0].Name -replace '^\\\\', ''
}

# --------------------------------------------------- 3. kaynak makinede arama
if ($kaynak -and $kaynak -ne '-') {
    Yaz "`n--- 3. $kaynak üzerinde eski parola arayışı ---" Baslik

    $blok = {
        param($ad)
        $sonuc = [ordered]@{}
        $sonuc['KimlikDeposu'] = (cmdkey /list | Select-String 'Target:') -join "`n"
        $sonuc['ZamanlanmisGorevler'] = (Get-ScheduledTask | Where-Object {
                $_.Principal.UserId -like "*$ad*"
            } | Select-Object TaskName, TaskPath | Out-String)
        $sonuc['Servisler'] = (Get-CimInstance Win32_Service | Where-Object {
                $_.StartName -like "*$ad*"
            } | Select-Object Name, StartName | Out-String)
        $sonuc
    }

    $uzak = Invoke-Command -ComputerName $kaynak -ScriptBlock $blok -ArgumentList $hesap.SamAccountName -ErrorAction SilentlyContinue

    if ($uzak) {
        foreach ($anahtar in 'KimlikDeposu', 'ZamanlanmisGorevler', 'Servisler') {
            Yaz "`n[$anahtar]" Baslik
            if ($uzak[$anahtar] -and $uzak[$anahtar].Trim()) { Write-Host $uzak[$anahtar] }
            else { Yaz '  (kayıt yok)' Bilgi }
        }
    } else {
        Yaz "Uzak makineye bağlanılamadı. Aynı kontrolleri $kaynak üzerinde elle yapın:" Uyari
        Yaz '  cmdkey /list'
        Yaz "  Get-ScheduledTask | Where-Object { `$_.Principal.UserId -like '*$($hesap.SamAccountName)*' }"
        Yaz "  Get-CimInstance Win32_Service | Where-Object { `$_.StartName -like '*$($hesap.SamAccountName)*' }"
    }
}

# ------------------------------------------------------------ kilidi açma
if ($KilidiAc -and $hesap.LockedOut) {
    Yaz "`n--- Kilit açılıyor ---" Baslik
    Unlock-ADAccount -Identity $hesap.SamAccountName
    Yaz 'Kilit açıldı. Sebep bulunmadıysa birkaç dakika içinde tekrar kilitlenecektir.' Uyari
}

Yaz "`n--- Özet ---" Baslik
Yaz 'Kilit sebebi sıralaması (sahada görülme sıklığına göre):'
Yaz '  1. Telefonda kayıtlı eski e-posta parolası (Exchange/ActiveSync)'
Yaz '  2. Kilit ekranında açık kalmış ikinci oturum'
Yaz '  3. Eski parolayla çalışan zamanlanmış görev ya da servis'
Yaz '  4. Eşlenmiş ağ sürücüsü / kimlik deposundaki eski kayıt'
Yaz '  5. Kullanıcının gerçekten parolayı yanlış girmesi (en az rastlanan)'
