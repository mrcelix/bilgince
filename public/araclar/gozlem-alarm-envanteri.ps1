<#
.SYNOPSIS
    Alarm kurallarını gürültü ve kapsam açısından değerlendirir.

.DESCRIPTION
    Alarm yorgunluğu ölçülebilir bir şeydir: en çok çalan üç alarm
    genelde tüm bildirimlerin yarısını üretir. Bu betik Prometheus
    Alertmanager'dan alarm geçmişini çeker, en çok tetiklenenleri sayar ve
    hiç tetiklenmemiş (muhtemelen bozuk) kuralları listeler.

    Değişiklik yapmaz.

.PARAMETER Adres
    Prometheus adresi, örn. http://prom:9090

.PARAMETER Gun
    Kaç günlük geçmişe bakılsın. Varsayılan 30.

.EXAMPLE
    .\gozlem-alarm-envanteri.ps1 -Adres http://prom:9090

.NOTES
    bilgince.com — Hızlı Çözümler
    Prometheus HTTP API erişimi gerekir. Uzun aralıklar büyük kümelerde yavaştır.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Adres,
    [int]$Gun = 30
)

function Sorgula([string]$ifade) {
    $u = "$Adres/api/v1/query?query=" + [uri]::EscapeDataString($ifade)
    try { (Invoke-RestMethod -Uri $u -TimeoutSec 60).data.result }
    catch { Write-Warning "Sorgu başarısız: $ifade"; @() }
}

Write-Host "== En çok tetiklenen alarmlar ($Gun gün)" -ForegroundColor Cyan
# Tek tırnaklı dizge: içindeki çift tırnakları kaçırmaya gerek kalmıyor
$ifadeCok = 'sort_desc(count_over_time(ALERTS{alertstate="firing"}[' + $Gun + 'd]))'
Sorgula $ifadeCok |
    ForEach-Object {
        [pscustomobject]@{
            Alarm = $_.metric.alertname
            Ciddiyet = $_.metric.severity
            Ornek = [int]$_.value[1]
        }
    } | Select-Object -First 15 | Format-Table -AutoSize

Write-Host "== Şu an çalan alarmlar" -ForegroundColor Cyan
Sorgula 'ALERTS{alertstate="firing"}' |
    ForEach-Object { [pscustomobject]@{ Alarm = $_.metric.alertname; Hedef = $_.metric.instance } } |
    Format-Table -AutoSize

Write-Host "== Veri göndermeyi bırakmış hedefler" -ForegroundColor Cyan
$olu = Sorgula "up == 0"
if ($olu) {
    $olu | ForEach-Object { [pscustomobject]@{ Is = $_.metric.job; Hedef = $_.metric.instance } } |
        Format-Table -AutoSize
    Write-Host "Sessizce ölen izleme budur: hedef kayıtlı ama veri yok." -ForegroundColor Yellow
} else {
    Write-Host "Tüm hedefler veri gönderiyor." -ForegroundColor Green
}

Write-Host "İlk üç alarm bildirimlerin yarısını üretiyorsa eşiği değil, kuralı sorgulayın." -ForegroundColor Yellow
