<#
.SYNOPSIS
    Küme kaynak isteklerini ve gerçek kullanımı karşılaştırır.

.DESCRIPTION
    Kapasite tartışmaları tahminle yapılır: "küme dolu" denir ama
    istekler mi doldurdu, gerçek kullanım mı belli olmaz. Bu betik düğüm
    başına ayrılmış istekleri, sınırları ve metrics-server varsa gerçek
    kullanımı yan yana koyar.

    Değişiklik yapmaz.

.PARAMETER AdAlani
    Yalnızca bir ad alanına bakmak için.

.EXAMPLE
    .\k8s-kaynak-envanteri.ps1

.NOTES
    bilgince.com — Hızlı Çözümler
    Gerçek kullanım için metrics-server gerekir; yoksa yalnızca istekler raporlanır.
#>

[CmdletBinding()]
param([string]$AdAlani)

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl bulunamadı."
    return
}

Write-Host "== Düğüm kapasitesi ve ayrılan istekler" -ForegroundColor Cyan
# `foreach` deyimi boruya bağlanamaz; ForEach-Object kullanılıyor
$dugumler = (kubectl get nodes -o json | ConvertFrom-Json).items
$dugumler | ForEach-Object {
    [pscustomobject]@{
        Dugum          = $_.metadata.name
        CPUKapasite    = $_.status.capacity.cpu
        BellekKapasite = $_.status.capacity.memory
        Durum          = ($_.status.conditions | Where-Object { $_.type -eq 'Ready' }).status
        # Zamanlanamaz düğüm kapasiteyi doldurmuş gibi görünür ama aslında kapalıdır
        Zamanlanabilir = -not $_.spec.unschedulable
    }
} | Format-Table -AutoSize

Write-Host ""
Write-Host "== Sınırı olmayan konteynerler" -ForegroundColor Cyan
$kapsam = if ($AdAlani) { @('-n', $AdAlani) } else { @('--all-namespaces') }
$podlar = (kubectl get pods @kapsam -o json | ConvertFrom-Json).items
$sinirsiz = foreach ($p in $podlar) {
    foreach ($c in $p.spec.containers) {
        if (-not $c.resources.limits) {
            [pscustomobject]@{
                AdAlani = $p.metadata.namespace
                Pod = $p.metadata.name
                Konteyner = $c.name
            }
        }
    }
}
if ($sinirsiz) { $sinirsiz | Format-Table -AutoSize }
else { Write-Host "Tüm konteynerlerde sınır tanımlı." -ForegroundColor Green }

Write-Host ""
Write-Host "== Gerçek kullanım (metrics-server)" -ForegroundColor Cyan
$metrik = kubectl top nodes 2>$null
if ($LASTEXITCODE -eq 0) { $metrik }
else { Write-Host "metrics-server yok; gerçek kullanım okunamadı." -ForegroundColor Yellow }
