<#
.SYNOPSIS
    Unutulmuş sanal makine anlık görüntülerini bulur.

.DESCRIPTION
    Anlık görüntü geçici olmak üzere alınır, kalıcı olur. Uzun yaşayan
    zincirler hem disk yer hem de birleştirme sırasında uzun kesinti
    üretir. Betik yaşa ve boyuta göre sıralar, zincir uzunluğunu gösterir.

    Değişiklik yapmaz.

.PARAMETER GunSayisi
    Kaç günden eski anlık görüntüler işaretlensin. Varsayılan 7.

.EXAMPLE
    .\depolama-anlik-goruntu-denetimi.ps1 -GunSayisi 3

.NOTES
    bilgince.com — Hızlı Çözümler
    Hyper-V modülü gerekir. Silme işlemi yapmaz; birleştirme iş saatleri dışında planlanmalı.
#>

[CmdletBinding()]
param([int]$GunSayisi = 7)

Import-Module Hyper-V -ErrorAction Stop
$sinir = (Get-Date).AddDays(-$GunSayisi)

$anlik = Get-VM | Get-VMSnapshot
if (-not $anlik) {
    Write-Host "Anlık görüntü yok." -ForegroundColor Green
    return
}

Write-Host "== Tüm anlık görüntüler" -ForegroundColor Cyan
$anlik | ForEach-Object {
    $boyutGB = 0
    try { $boyutGB = [math]::Round((Get-Item $_.Path -ErrorAction Stop).Length / 1GB, 2) } catch {}
    [pscustomobject]@{
        VM       = $_.VMName
        Ad       = $_.Name
        Olusturma = $_.CreationTime
        YasGun   = [int]((Get-Date) - $_.CreationTime).TotalDays
        BoyutGB  = $boyutGB
        Eski     = $_.CreationTime -lt $sinir
    }
} | Sort-Object YasGun -Descending | Format-Table -AutoSize

Write-Host "== Zincir uzunluğu (aynı VM'de birden çok anlık görüntü)" -ForegroundColor Cyan
$anlik | Group-Object VMName | Where-Object Count -gt 1 |
    Sort-Object Count -Descending |
    Select-Object @{ n = 'VM'; e = { $_.Name } }, @{ n = 'AnlikSayisi'; e = { $_.Count } } |
    Format-Table -AutoSize

$eskiler = $anlik | Where-Object { $_.CreationTime -lt $sinir }
if ($eskiler) {
    Write-Host "$($eskiler.Count) anlık görüntü $GunSayisi günden eski." -ForegroundColor Yellow
    Write-Host "Birleştirme disk G/Ç'sini doyurur; iş saatleri dışında planlayın." -ForegroundColor Yellow
} else {
    Write-Host "Eski anlık görüntü yok." -ForegroundColor Green
}
