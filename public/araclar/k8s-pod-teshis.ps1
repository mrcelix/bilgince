<#
.SYNOPSIS
    Sorunlu Kubernetes podlarını tek raporda toplar.

.DESCRIPTION
    Bir pod "çalışmıyor" dendiğinde bakılacak dört yer vardır: durumu,
    yeniden başlatma sayısı, son olayları ve konteyner çıkış kodu. Bu betik
    dördünü tek çıktıda birleştirir; kubectl komutlarını tek tek yazmaya
    gerek kalmaz.

    Değişiklik yapmaz.

.PARAMETER AdAlani
    Taranacak ad alanı. Verilmezse tüm ad alanları.

.PARAMETER RestartEsigi
    Kaç yeniden başlatmadan sonra pod şüpheli sayılsın. Varsayılan 3.

.EXAMPLE
    .\k8s-pod-teshis.ps1 -AdAlani uretim -RestartEsigi 5

.NOTES
    bilgince.com — Hızlı Çözümler
    kubectl PATH üzerinde ve kubeconfig ayarlı olmalı.
#>

[CmdletBinding()]
param(
    [string]$AdAlani,
    [int]$RestartEsigi = 3
)

$kapsam = if ($AdAlani) { @('-n', $AdAlani) } else { @('--all-namespaces') }

function Yaz-Baslik([string]$m) {
    Write-Host ""
    Write-Host "== $m" -ForegroundColor Cyan
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl bulunamadı. PATH üzerinde olmalı."
    return
}

Yaz-Baslik "Hazır olmayan podlar"
$ham = kubectl get pods @kapsam -o json | ConvertFrom-Json
$sorunlu = $ham.items | Where-Object {
    $_.status.phase -notin 'Running', 'Succeeded' -or
    ($_.status.containerStatuses | Where-Object { -not $_.ready })
}

if (-not $sorunlu) {
    Write-Host "Hazır olmayan pod yok." -ForegroundColor Green
} else {
    $sorunlu | ForEach-Object {
        [pscustomobject]@{
            AdAlani  = $_.metadata.namespace
            Pod      = $_.metadata.name
            Durum    = $_.status.phase
            Restart  = ($_.status.containerStatuses | Measure-Object restartCount -Sum).Sum
            Sebep    = ($_.status.containerStatuses |
                        ForEach-Object { if ($_.state.waiting.reason) { $_.state.waiting.reason } else { $_.lastState.terminated.reason } } |
                        Where-Object { $_ } | Select-Object -First 1)
        }
    } | Format-Table -AutoSize
}

Yaz-Baslik "Eşiği aşan yeniden başlatmalar (>= $RestartEsigi)"
$ham.items | ForEach-Object {
    $toplam = ($_.status.containerStatuses | Measure-Object restartCount -Sum).Sum
    if ($toplam -ge $RestartEsigi) {
        [pscustomobject]@{
            AdAlani = $_.metadata.namespace
            Pod     = $_.metadata.name
            Restart = $toplam
            # Son çıkış kodu neden düştüğünü söyler: 137 = OOMKilled, 1 = uygulama hatası
            CikisKodu = ($_.status.containerStatuses | ForEach-Object { $_.lastState.terminated.exitCode } |
                         Where-Object { $_ -ne $null } | Select-Object -First 1)
        }
    }
} | Sort-Object Restart -Descending | Format-Table -AutoSize

Yaz-Baslik "Son uyarı olayları"
kubectl get events @kapsam --field-selector type=Warning --sort-by='.lastTimestamp' 2>$null |
    Select-Object -Last 15

Write-Host ""
Write-Host "Çıkış kodu 137 gördüyseniz bellek sınırı yetersiz; 1 ise uygulama hatası." -ForegroundColor Yellow
