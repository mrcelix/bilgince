<#
.SYNOPSIS
    Makinenin Windows 11 gereksinimlerini karşılayıp karşılamadığını, hangi
    maddede takıldığını ve maddenin düzeltilebilir olup olmadığını raporlar.

.DESCRIPTION
    Yedi maddeye bakar: TPM 2.0, Secure Boot, UEFI, işlemci, bellek, sistem
    diski alanı ve işlemci mimarisi. Her madde için "uygun / uygun değil /
    açılabilir" sonucu verir — çünkü sahadaki makinelerin çoğu uyumsuz değil,
    yalnızca BIOS'ta kapalıdır.

    Hiçbir ayarı değiştirmez. Filo genelinde çalıştırıp CSV toplamak için
    -Csv parametresini kullanın.

.PARAMETER Csv
    Sonucu tek satırlık nesne olarak da döndürür (Export-Csv ile toplanabilir).

.EXAMPLE
    .\win11-uyumluluk.ps1
    .\win11-uyumluluk.ps1 -Csv | Export-Csv .\uyumluluk.csv -NoTypeInformation -Encoding UTF8

.NOTES
    bilgince.com — Hızlı Çözümler
#>

[CmdletBinding()]
param(
    [switch]$Csv
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

$bulgular = [ordered]@{}
$engel = @()
$acilabilir = @()

Yaz "=== Windows 11 uyumluluk — $env:COMPUTERNAME ===" Baslik
$os = Get-CimInstance Win32_OperatingSystem
Yaz ("Şu anki sürüm: {0} ({1})" -f $os.Caption, $os.Version)

# ------------------------------------------------------------------- 1. TPM
$tpm = Get-Tpm
$tpmSurum = (Get-CimInstance -Namespace root\cimv2\security\microsofttpm -ClassName Win32_Tpm).SpecVersion
$tpmSurumNo = if ($tpmSurum) { ($tpmSurum -split ',')[0].Trim() } else { $null }

if (-not $tpm.TpmPresent) {
    $tpmSonuc = 'YOK'
    $engel += 'TPM yongası bulunamadı'
} elseif ($tpmSurumNo -like '1.2*') {
    $tpmSonuc = 'TPM 1.2 — yetersiz'
    $engel += 'TPM 1.2 (2.0 gerekir)'
} elseif (-not $tpm.TpmReady) {
    $tpmSonuc = "TPM $tpmSurumNo var ama hazır değil"
    $acilabilir += 'TPM BIOS''ta etkinleştirilmeli (Intel PTT / AMD fTPM)'
} else {
    $tpmSonuc = "TPM $tpmSurumNo hazır"
}
$bulgular['TPM'] = $tpmSonuc

# ------------------------------------------------------------ 2. Secure Boot
$secureBoot = try { Confirm-SecureBootUEFI } catch { $null }
if ($null -eq $secureBoot) {
    $sbSonuc = 'UEFI değil (Legacy/BIOS)'
    $acilabilir += 'Disk MBR2GPT ile dönüştürülüp UEFI moduna geçilmeli'
} elseif (-not $secureBoot) {
    $sbSonuc = 'UEFI var, Secure Boot kapalı'
    $acilabilir += 'Secure Boot BIOS''tan açılmalı'
} else {
    $sbSonuc = 'Açık'
}
$bulgular['SecureBoot'] = $sbSonuc

# --------------------------------------------------------------- 3. işlemci
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$bulgular['Islemci'] = $cpu.Name.Trim()
$bulgular['Cekirdek'] = $cpu.NumberOfCores
$bulgular['Mimari'] = if ($cpu.AddressWidth -eq 64) { '64 bit' } else { '32 bit' }

if ($cpu.NumberOfCores -lt 2) { $engel += 'İşlemci 2 çekirdekten az' }
if ($cpu.MaxClockSpeed -lt 1000) { $engel += 'İşlemci hızı 1 GHz altında' }
if ($cpu.AddressWidth -ne 64) { $engel += '64 bit değil' }

# Nesil kontrolü kaba: model adındaki nesil numarasına bakar
$nesil = $null
if ($cpu.Name -match 'i[3579]-(\d{4,5})') { $nesil = [int]($matches[1].Substring(0, $matches[1].Length - 3)) }
if ($nesil -and $nesil -lt 8) {
    $engel += "Intel $nesil. nesil — desteklenen liste 8. nesilde başlıyor"
}
$bulgular['Nesil'] = if ($nesil) { "$nesil. nesil" } else { 'okunamadı' }

# ---------------------------------------------------------------- 4. bellek
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$bulgular['RAM_GB'] = $ramGB
if ($ramGB -lt 4) { $engel += "Bellek $ramGB GB (en az 4 GB)" }

# ------------------------------------------------------------------ 5. disk
$sistemDisk = Get-PSDrive C
$diskGB = [math]::Round(($sistemDisk.Used + $sistemDisk.Free) / 1GB)
$bosGB = [math]::Round($sistemDisk.Free / 1GB, 1)
$bulgular['Disk_GB'] = $diskGB
$bulgular['Bos_GB'] = $bosGB
if ($diskGB -lt 64) { $engel += "Sistem diski $diskGB GB (en az 64 GB)" }
if ($bosGB -lt 25) { $acilabilir += "Yükseltme için yer açılmalı (şu an $bosGB GB boş, ~25 GB gerekir)" }

# ------------------------------------------------------------------- rapor
Yaz "`n--- Bulgular ---" Baslik
$bulgular.GetEnumerator() | ForEach-Object { '{0,-12} {1}' -f $_.Key, $_.Value } | ForEach-Object { Yaz "  $_" }

Yaz "`n--- Sonuç ---" Baslik
if ($engel.Count -eq 0 -and $acilabilir.Count -eq 0) {
    Yaz 'UYGUN — Windows 11 gereksinimlerinin tamamı karşılanıyor.' Iyi
} elseif ($engel.Count -eq 0) {
    Yaz 'AYAR GEREKİYOR — donanım yeterli, aşağıdakiler açılmalı:' Uyari
    $acilabilir | ForEach-Object { Yaz "  • $_" Uyari }
} else {
    Yaz 'UYGUN DEĞİL — donanım kaynaklı engeller:' Hata
    $engel | ForEach-Object { Yaz "  • $_" Hata }
    if ($acilabilir) {
        Yaz 'Ayrıca ayar gerektirenler:' Uyari
        $acilabilir | ForEach-Object { Yaz "  • $_" Uyari }
    }
}

Yaz "`nNot: TPM ve Secure Boot maddelerinin çoğu BIOS'ta kapalı olmaktan kaynaklanır." Bilgi
Yaz 'Donanımı değiştirmeden önce BIOS ayarlarını kontrol edin: sahadaki "uyumsuz" makinelerin büyük kısmı aslında uyumludur.'

if ($Csv) {
    [pscustomobject]@{
        Makine     = $env:COMPUTERNAME
        Tarih      = Get-Date -f 'yyyy-MM-dd'
        Sonuc      = if ($engel.Count) { 'UYGUN DEGIL' } elseif ($acilabilir.Count) { 'AYAR GEREKIYOR' } else { 'UYGUN' }
        Engeller   = ($engel -join ' | ')
        Ayarlar    = ($acilabilir -join ' | ')
        TPM        = $bulgular['TPM']
        SecureBoot = $bulgular['SecureBoot']
        Islemci    = $bulgular['Islemci']
        RAM_GB     = $ramGB
        Bos_GB     = $bosGB
    }
}
