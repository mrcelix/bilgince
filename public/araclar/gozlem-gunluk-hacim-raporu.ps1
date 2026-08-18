<#
.SYNOPSIS
    Günlük hacmini kaynak bazında raporlar; maliyeti kimin ürettiğini gösterir.

.DESCRIPTION
    Günlük toplama faturası hacimle büyür ama hacmi kimin ürettiği
    görünmez. Bu betik Windows olay günlüklerinin boyutunu, en çok yazan
    kaynakları ve tekrar eden olay kimliklerini çıkarır — gürültü üreten
    tek bir bileşen genelde faturanın yarısıdır.

    Değişiklik yapmaz.

.PARAMETER Saat
    Kaç saatlik geçmişe bakılsın. Varsayılan 24.

.EXAMPLE
    .\gozlem-gunluk-hacim-raporu.ps1 -Saat 6

.NOTES
    bilgince.com — Hızlı Çözümler
    Yalnızca yerel Windows olay günlüklerini kapsar.
#>

[CmdletBinding()]
param([int]$Saat = 24)

$baslangic = (Get-Date).AddHours(-$Saat)

Write-Host "== Günlük dosyalarının boyutu" -ForegroundColor Cyan
Get-WinEvent -ListLog * -ErrorAction SilentlyContinue |
    Where-Object { $_.RecordCount -gt 0 } |
    Sort-Object FileSize -Descending | Select-Object -First 12 |
    ForEach-Object {
        [pscustomobject]@{
            Gunluk  = $_.LogName
            BoyutMB = [math]::Round($_.FileSize / 1MB, 1)
            Kayit   = $_.RecordCount
            EnBuyukMB = [math]::Round($_.MaximumSizeInBytes / 1MB, 0)
        }
    } | Format-Table -AutoSize

Write-Host "== Son $Saat saatte en çok yazan kaynaklar" -ForegroundColor Cyan
$olaylar = Get-WinEvent -FilterHashtable @{
    LogName = 'System', 'Application'; StartTime = $baslangic
} -ErrorAction SilentlyContinue

if (-not $olaylar) {
    Write-Host "Bu aralıkta olay yok." -ForegroundColor Green
    return
}

$olaylar | Group-Object ProviderName | Sort-Object Count -Descending |
    Select-Object -First 12 Count, Name | Format-Table -AutoSize

Write-Host "== En çok tekrar eden olaylar" -ForegroundColor Cyan
$olaylar | Group-Object Id, ProviderName | Sort-Object Count -Descending |
    Select-Object -First 12 |
    ForEach-Object {
        $p = $_.Group[0]
        [pscustomobject]@{
            Adet   = $_.Count
            Id     = $p.Id
            Kaynak = $p.ProviderName
            Ornek  = $p.Message.Split([char]10)[0].Substring(0, [Math]::Min(70, $p.Message.Split([char]10)[0].Length))
        }
    } | Format-Table -AutoSize

Write-Host "Toplam olay: $($olaylar.Count) | Saatte ortalama: $([int]($olaylar.Count / $Saat))" -ForegroundColor Yellow
