<#
.SYNOPSIS
    SQL Server örneğinin operasyonel sağlığını denetler.

.DESCRIPTION
    Veritabanı "yavaş" dendiğinde bakılacak sabit bir liste vardır:
    kurtarma modeli ve günlük büyümesi, yedek yaşı, otomatik küçültme gibi
    kötü ayarlar, uzun süren sorgular ve bekleme türleri. Betik bunları
    sırayla raporlar.

    Değişiklik yapmaz.

.PARAMETER Ornek
    SQL Server örneği. Varsayılan yerel makine.

.EXAMPLE
    .\sql-saglik-kontrol.ps1 -Ornek "SQL01\URETIM"

.NOTES
    bilgince.com — Hızlı Çözümler
    SqlServer modülü gerekir: Install-Module SqlServer. VIEW SERVER STATE izni ister.
#>

[CmdletBinding()]
param([string]$Ornek = $env:COMPUTERNAME)

if (-not (Get-Module -ListAvailable SqlServer)) {
    Write-Error "SqlServer modülü yok: Install-Module SqlServer -Scope CurrentUser"
    return
}
Import-Module SqlServer -ErrorAction Stop

function Sorgu([string]$metin) {
    Invoke-Sqlcmd -ServerInstance $Ornek -Query $metin -ErrorAction Stop
}

Write-Host "== Veritabanı ayarları" -ForegroundColor Cyan
Sorgu @"
SELECT name AS veritabani, recovery_model_desc AS kurtarma,
       is_auto_shrink_on AS otomatik_kucultme,
       is_auto_close_on AS otomatik_kapatma,
       state_desc AS durum, compatibility_level AS uyumluluk
FROM sys.databases WHERE database_id > 4 ORDER BY name;
"@ | Format-Table -AutoSize

Write-Host "== Yedek yaşı" -ForegroundColor Cyan
Sorgu @"
SELECT d.name AS veritabani,
  DATEDIFF(hour, MAX(CASE WHEN b.type='D' THEN b.backup_finish_date END), GETDATE()) AS tam_yedek_saat,
  DATEDIFF(hour, MAX(CASE WHEN b.type='L' THEN b.backup_finish_date END), GETDATE()) AS gunluk_yedek_saat
FROM sys.databases d LEFT JOIN msdb.dbo.backupset b ON b.database_name = d.name
WHERE d.database_id > 4 GROUP BY d.name ORDER BY tam_yedek_saat DESC;
"@ | Format-Table -AutoSize

Write-Host "== En çok beklenen kaynaklar" -ForegroundColor Cyan
Sorgu @"
SELECT TOP 10 wait_type, wait_time_ms / 1000 AS saniye, waiting_tasks_count AS bekleyen
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%' AND wait_type NOT LIKE 'BROKER%'
  AND wait_type NOT IN ('CLR_AUTO_EVENT','XE_TIMER_EVENT','REQUEST_FOR_DEADLOCK_SEARCH')
ORDER BY wait_time_ms DESC;
"@ | Format-Table -AutoSize

Write-Host "== Şu an uzun süren sorgular" -ForegroundColor Cyan
Sorgu @"
SELECT r.session_id, r.status, r.wait_type,
       r.total_elapsed_time/1000 AS saniye, DB_NAME(r.database_id) AS veritabani
FROM sys.dm_exec_requests r
WHERE r.session_id > 50 AND r.total_elapsed_time > 5000
ORDER BY r.total_elapsed_time DESC;
"@ | Format-Table -AutoSize

Write-Host "Otomatik küçültme açıksa kapatın: sürekli parçalanma üretir." -ForegroundColor Yellow
