<#
.SYNOPSIS
    Paylaşımların büyüme hızını ölçüp doluluk tarihini tahmin eder.

.DESCRIPTION
    Kapasite planlaması "şu an ne kadar dolu" ile değil "ne hızla doluyor"
    ile yapılır. Betik her çalıştığında ölçüm alır ve önceki ölçümle
    karşılaştırıp günlük büyümeyi, kalan gün sayısını hesaplar.

    Değişiklik yapmaz.

.PARAMETER OlcumDosyasi
    Önceki ölçümün tutulduğu CSV. Varsayılan TEMP altında.

.EXAMPLE
    .\depolama-buyume-raporu.ps1

.NOTES
    bilgince.com — Hızlı Çözümler
    İlk çalıştırma yalnızca ölçüm alır; tahmin ikinci çalıştırmada çıkar. Haftalık zamanlanmış görev olarak işe yarar.
#>

[CmdletBinding()]
param([string]$OlcumDosyasi = "$env:TEMP\bilgince-depolama-olcum.csv")

$simdi = Get-Date

Write-Host "== Birim doluluğu" -ForegroundColor Cyan
$birimler = Get-Volume | Where-Object { $_.DriveLetter -and $_.Size -gt 0 } | ForEach-Object {
    [pscustomobject]@{
        Tarih      = $simdi
        Birim      = $_.DriveLetter
        ToplamGB   = [math]::Round($_.Size / 1GB, 2)
        BosGB      = [math]::Round($_.SizeRemaining / 1GB, 2)
        DoluYuzde  = [math]::Round((1 - $_.SizeRemaining / $_.Size) * 100, 1)
    }
}
$birimler | Format-Table Birim, ToplamGB, BosGB, DoluYuzde -AutoSize

if (Test-Path $OlcumDosyasi) {
    Write-Host "== Büyüme ve tahmini doluluk" -ForegroundColor Cyan
    $onceki = Import-Csv $OlcumDosyasi
    # `foreach` bir deyimdir, boruya bağlanamaz; $(...) ile ifadeye çevriliyor
    $(foreach ($bir in $birimler) {
        $e = $onceki | Where-Object { $_.Birim -eq $bir.Birim } | Sort-Object Tarih | Select-Object -Last 1
        if (-not $e) { continue }

        $gecenGun = ($simdi - [datetime]$e.Tarih).TotalDays
        if ($gecenGun -lt 0.5) { continue }

        $tuketilenGB = [double]$e.BosGB - $bir.BosGB
        $gunlukGB = [math]::Round($tuketilenGB / $gecenGun, 2)
        $kalanGun = if ($gunlukGB -gt 0) { [int]($bir.BosGB / $gunlukGB) } else { $null }

        [pscustomobject]@{
            Birim       = $bir.Birim
            GunlukGB    = $gunlukGB
            BosGB       = $bir.BosGB
            TahminiGun  = if ($null -ne $kalanGun) { $kalanGun } else { 'büyümüyor' }
        }
    }) | Format-Table -AutoSize
} else {
    Write-Host "İlk ölçüm alındı. Tahmin için betiği birkaç gün sonra tekrar çalıştırın." -ForegroundColor Yellow
}

$birimler | Export-Csv $OlcumDosyasi -NoTypeInformation -Append -Encoding UTF8
Write-Host "Ölçüm kaydedildi: $OlcumDosyasi" -ForegroundColor Green
