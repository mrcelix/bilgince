<#
.SYNOPSIS
    Yedeklerin varlığını değil, geri dönebilirliğini sınar.

.DESCRIPTION
    "Yedek başarılı" mesajı yedeğin okunabildiğini kanıtlamaz. Bu
    betik her veritabanının son yedeğini bulur, RESTORE VERIFYONLY ile
    dosyayı doğrular ve zincirdeki boşlukları raporlar.

    Değişiklik yapmaz.

.PARAMETER Ornek
    SQL Server örneği.

.PARAMETER GunSayisi
    Kaç günlük yedek geçmişine bakılsın. Varsayılan 7.

.EXAMPLE
    .\sql-yedek-dogrulama.ps1 -GunSayisi 3

.NOTES
    bilgince.com — Hızlı Çözümler
    VERIFYONLY yedeği geri yüklemez ama dosyayı baştan sona okur; büyük yedeklerde süre alır.
#>

[CmdletBinding()]
param(
    [string]$Ornek = $env:COMPUTERNAME,
    [int]$GunSayisi = 7
)

Import-Module SqlServer -ErrorAction Stop

$sonYedekler = Invoke-Sqlcmd -ServerInstance $Ornek -Query @"
SELECT b.database_name, b.type, b.backup_finish_date, f.physical_device_name
FROM msdb.dbo.backupset b
JOIN msdb.dbo.backupmediafamily f ON f.media_set_id = b.media_set_id
WHERE b.backup_finish_date > DATEADD(day, -$GunSayisi, GETDATE())
  AND b.type = 'D'
ORDER BY b.backup_finish_date DESC;
"@

if (-not $sonYedekler) {
    Write-Warning "$GunSayisi gün içinde tam yedek kaydı yok."
    return
}

$sonuc = foreach ($y in ($sonYedekler | Group-Object database_name | ForEach-Object { $_.Group[0] })) {
    $yol = $y.physical_device_name
    $durum = if (-not (Test-Path $yol)) {
        'DOSYA YOK'
    } else {
        try {
            Invoke-Sqlcmd -ServerInstance $Ornek -Query "RESTORE VERIFYONLY FROM DISK = N'$yol'" -ErrorAction Stop | Out-Null
            'Doğrulandı'
        } catch {
            "HATA: $($_.Exception.Message.Split([char]10)[0])"
        }
    }
    [pscustomobject]@{
        Veritabani = $y.database_name
        Tarih      = $y.backup_finish_date
        YasSaat    = [int]((Get-Date) - $y.backup_finish_date).TotalHours
        Durum      = $durum
    }
}

$sonuc | Sort-Object YasSaat -Descending | Format-Table -AutoSize

$kotu = $sonuc | Where-Object Durum -ne 'Doğrulandı'
if ($kotu) {
    Write-Host ""
    Write-Host "$($kotu.Count) yedek doğrulanamadı. Geri dönüş tatbikatı yapılmadan bu yedeklere güvenmeyin." -ForegroundColor Red
} else {
    Write-Host "Tüm yedekler okunabilir durumda." -ForegroundColor Green
}
