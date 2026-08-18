<#
.SYNOPSIS
    Dosya paylaşımlarının paylaşım ve NTFS izinlerini birlikte raporlar.

.DESCRIPTION
    "Erişimim yok" ve "herkes her yeri görüyor" şikâyetlerinin ikisi de aynı
    yerden çıkar: paylaşım izni ile NTFS izninin kesişimi. Bu betik ikisini yan
    yana koyar, kalıtımı kırılmış klasörleri bulur ve "Everyone" gibi geniş
    yetkileri işaretler.

    Değişiklik yapmaz.

.PARAMETER Yol
    Taranacak kök klasör. Verilmezse makinedeki tüm paylaşımlar taranır.

.PARAMETER Derinlik
    Alt klasörlerde kaç seviye inileceği. Varsayılan 2.

.EXAMPLE
    .\paylasim-izin-raporu.ps1
    .\paylasim-izin-raporu.ps1 -Yol D:\Ortak -Derinlik 3

.NOTES
    bilgince.com — Hızlı Çözümler
#>

[CmdletBinding()]
param(
    [string]$Yol,
    [int]$Derinlik = 2
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

$genisGruplar = 'Everyone', 'Authenticated Users', 'Users', 'Domain Users', 'Herkes', 'Kullanıcılar'
$tehlikeliHak = 'FullControl', 'Modify', 'Write'

Yaz "=== Paylaşım ve izin raporu — $env:COMPUTERNAME ===" Baslik

# --------------------------------------------------------- 1. paylaşımlar
Yaz "`n--- 1. Paylaşımlar ve paylaşım izinleri ---" Baslik
$paylasimlar = Get-SmbShare | Where-Object { $_.Name -notmatch '^\w\$$|^(IPC|ADMIN|print)\$$' }

if (-not $paylasimlar) {
    Yaz 'Yönetimsel olmayan paylaşım yok.' Uyari
} else {
    foreach ($p in $paylasimlar) {
        Yaz "`n[$($p.Name)] → $($p.Path)" Baslik
        $izinler = Get-SmbShareAccess -Name $p.Name
        $izinler | Select-Object AccountName, AccessRight, AccessControlType | Format-Table -AutoSize

        $genis = $izinler | Where-Object {
            $_.AccessControlType -eq 'Allow' -and
            ($genisGruplar | Where-Object { $_.AccountName -like "*$_*" }) -and
            $_.AccessRight -in 'Full', 'Change'
        }
        if ($genis) {
            Yaz '  Paylaşım düzeyinde geniş yetki var. NTFS daraltmıyorsa herkes yazabilir.' Uyari
        }
    }
}

# ------------------------------------------------------------ 2. NTFS
$kokler = if ($Yol) { @($Yol) } else { $paylasimlar.Path | Sort-Object -Unique }

foreach ($kok in $kokler) {
    if (-not (Test-Path $kok)) { continue }
    Yaz "`n--- 2. NTFS izinleri: $kok ---" Baslik

    $klasorler = @(Get-Item $kok) + @(Get-ChildItem $kok -Directory -Recurse -Depth ($Derinlik - 1))

    foreach ($k in $klasorler) {
        $acl = Get-Acl $k.FullName
        $kalitimKirik = -not $acl.AreAccessRulesProtected -eq $false -and $acl.AreAccessRulesProtected

        $riskli = $acl.Access | Where-Object {
            $_.AccessControlType -eq 'Allow' -and
            $_.FileSystemRights -match ($tehlikeliHak -join '|') -and
            ($genisGruplar | ForEach-Object { $_ }) -contains ($_.IdentityReference.Value -replace '^.*\\', '')
        }

        if ($kalitimKirik -or $riskli) {
            Yaz "`n  $($k.FullName)" Baslik
            if ($kalitimKirik) { Yaz '    Kalıtım KIRIK — izinler üstten gelmiyor, burada ayrıca yönetiliyor.' Uyari }
            foreach ($r in $riskli) {
                Yaz "    $($r.IdentityReference) : $($r.FileSystemRights)" Hata
            }
            $acl.Access | Select-Object @{n='Kim';e={$_.IdentityReference}},
                @{n='Hak';e={$_.FileSystemRights}},
                @{n='Tur';e={$_.AccessControlType}},
                @{n='Kalitim';e={$_.IsInherited}} | Format-Table -AutoSize
        }
    }
}

# ------------------------------------------------------------- 3. özet
Yaz "`n--- 3. Nasıl okunur ---" Baslik
Yaz 'Etkin izin = paylaşım izni ile NTFS izninin KESİŞİMİ (daha dar olan kazanır).'
Yaz 'Yaygın ve doğru desen: paylaşımda "Authenticated Users — Change", NTFS''te gerçek yetkilendirme.'
Yaz 'Kalıtımı kırık her klasör, ileride kimsenin hatırlamayacağı bir istisnadır: gerekçesini belgeleyin.'
Yaz 'Kullanıcıya doğrudan izin vermeyin; gruba verin. Kişi ayrıldığında izin de ayrılsın.'
Yaz "`nBu betik hiçbir izni değiştirmedi."
