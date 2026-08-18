<#
.SYNOPSIS
    Paylaşımdaki dosyaları yaşa ve türe göre sınıflandırır.

.DESCRIPTION
    Arşivleme kararı için "ne kadar veri var" yetmez; "ne kadarına yıllardır
    dokunulmadı" gerekir. Betik bir yolu tarar, dosyaları son erişim yaşına
    göre kümeler ve en çok yer kaplayan uzantıları çıkarır.

    Değişiklik yapmaz.

.PARAMETER Yol
    Taranacak dizin.

.EXAMPLE
    .\depolama-dosya-yasi-analizi.ps1 -Yol D:\Paylasim

.NOTES
    bilgince.com — Hızlı Çözümler
    Büyük paylaşımlarda uzun sürer. Son erişim tarihi bazı birimlerde kapalıdır; o durumda değişim tarihi kullanılır.
#>

[CmdletBinding()]
param([Parameter(Mandatory)][string]$Yol)

if (-not (Test-Path $Yol)) { Write-Error "Yol yok: $Yol"; return }

Write-Host "Taranıyor: $Yol" -ForegroundColor Cyan
$dosyalar = Get-ChildItem $Yol -Recurse -File -ErrorAction SilentlyContinue
if (-not $dosyalar) { Write-Warning "Dosya bulunamadı ya da okunamadı."; return }

$simdi = Get-Date
$kovalar = @(
    @{ Ad = '0-90 gün';    Alt = 0;    Ust = 90 },
    @{ Ad = '90-365 gün';  Alt = 90;   Ust = 365 },
    @{ Ad = '1-3 yıl';     Alt = 365;  Ust = 1095 },
    @{ Ad = '3 yıldan eski'; Alt = 1095; Ust = [int]::MaxValue }
)

Write-Host "== Son erişim yaşına göre dağılım" -ForegroundColor Cyan
# `foreach` deyimi boruya bağlanamaz; $(...) ile ifadeye çevriliyor
$(foreach ($k in $kovalar) {
    $kume = $dosyalar | Where-Object {
        $yas = ($simdi - $_.LastAccessTime).TotalDays
        $yas -ge $k.Alt -and $yas -lt $k.Ust
    }
    [pscustomobject]@{
        Aralik  = $k.Ad
        Dosya   = $kume.Count
        BoyutGB = [math]::Round((($kume | Measure-Object Length -Sum).Sum) / 1GB, 2)
    }
}) | Format-Table -AutoSize

Write-Host "== En çok yer kaplayan uzantılar" -ForegroundColor Cyan
$dosyalar | Group-Object Extension | ForEach-Object {
    [pscustomobject]@{
        Uzanti  = if ($_.Name) { $_.Name } else { '(yok)' }
        Adet    = $_.Count
        BoyutGB = [math]::Round((($_.Group | Measure-Object Length -Sum).Sum) / 1GB, 2)
    }
} | Sort-Object BoyutGB -Descending | Select-Object -First 12 | Format-Table -AutoSize

$toplamGB = [math]::Round((($dosyalar | Measure-Object Length -Sum).Sum) / 1GB, 2)
$eski = $dosyalar | Where-Object { ($simdi - $_.LastAccessTime).TotalDays -gt 1095 }
$eskiGB = [math]::Round((($eski | Measure-Object Length -Sum).Sum) / 1GB, 2)

Write-Host "Toplam $toplamGB GB, bunun $eskiGB GB'ı 3 yıldır açılmamış." -ForegroundColor Yellow
Write-Host "Son erişim tarihi birimde kapalıysa bu sayı yanıltır: fsutil behavior query DisableLastAccess" -ForegroundColor Yellow
