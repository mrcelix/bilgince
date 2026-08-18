<#
.SYNOPSIS
    Sunucu envanterini donanım, rol ve yaşam döngüsüyle çıkarır.

.DESCRIPTION
    Envanter olmadan kapasite, lisans ve yenileme planlaması yapılamaz.
    Betik erişilebilen sunuculardan işletim sistemi sürümü, donanım,
    kurulu roller, disk doluluğu ve son açılış bilgisini toplar; destek
    süresi bitmiş sürümleri işaretler.

    Değişiklik yapmaz.

.PARAMETER Bilgisayarlar
    Taranacak makineler. Verilmezse AD'deki etkin sunucular.

.PARAMETER CiktiCsv
    Sonucun yazılacağı CSV dosyası.

.EXAMPLE
    .\envanter-sunucu-raporu.ps1 -CiktiCsv .\envanter.csv

.NOTES
    bilgince.com — Hızlı Çözümler
    WinRM gerekir. Destek bitiş bilgisi yaklaşık; kesin tarih için üreticinin yaşam döngüsü sayfasına bakın.
#>

[CmdletBinding()]
param(
    [string[]]$Bilgisayarlar,
    [string]$CiktiCsv
)

if (-not $Bilgisayarlar) {
    Import-Module ActiveDirectory -ErrorAction Stop
    $Bilgisayarlar = (Get-ADComputer -Filter { Enabled -eq $true -and OperatingSystem -like '*Server*' }).Name
}

# Yaklaşık genişletilmiş destek bitişleri
$destek = @{
    '2008' = '2020-01-14'; '2008 R2' = '2020-01-14'
    '2012' = '2023-10-10'; '2012 R2' = '2023-10-10'
    '2016' = '2027-01-12'; '2019' = '2029-01-09'; '2022' = '2031-10-14'
}

$ulasilamayan = @()
$envanter = foreach ($m in $Bilgisayarlar) {
    try {
        Invoke-Command -ComputerName $m -ErrorAction Stop -ScriptBlock {
            $isl = Get-CimInstance Win32_OperatingSystem
            $sis = Get-CimInstance Win32_ComputerSystem
            $roller = try {
                (Get-WindowsFeature | Where-Object { $_.Installed -and $_.FeatureType -eq 'Role' }).Name -join ', '
            } catch { '' }
            [pscustomobject]@{
                Makine    = $env:COMPUTERNAME
                Isletim   = $isl.Caption
                Surum     = $isl.Version
                RamGB     = [math]::Round($sis.TotalPhysicalMemory / 1GB, 0)
                Cekirdek  = $sis.NumberOfLogicalProcessors
                Uretici   = $sis.Manufacturer
                Model     = $sis.Model
                SonAcilis = $isl.LastBootUpTime
                Roller    = $roller
                CDoluYuzde = [math]::Round((1 - (Get-Volume -DriveLetter C).SizeRemaining /
                              (Get-Volume -DriveLetter C).Size) * 100, 1)
            }
        }
    } catch {
        $ulasilamayan += $m
    }
}

$zenginlestirilmis = $envanter | ForEach-Object {
    $kayit = $_
    $bitis = $null
    foreach ($k in $destek.Keys) { if ($kayit.Isletim -like "*$k*") { $bitis = $destek[$k] } }
    $disi = if ($bitis) { [datetime]$bitis -lt (Get-Date) } else { $false }

    $kayit | Add-Member -NotePropertyName DestekBitis -NotePropertyValue $bitis -PassThru |
        Add-Member -NotePropertyName DestekDisi -NotePropertyValue $disi -PassThru
}

Write-Host "== Envanter" -ForegroundColor Cyan
$zenginlestirilmis | Select-Object Makine, Isletim, RamGB, Cekirdek, CDoluYuzde, DestekBitis |
    Sort-Object Isletim | Format-Table -AutoSize

Write-Host "== Destek süresi bitmiş sunucular" -ForegroundColor Cyan
$eski = $zenginlestirilmis | Where-Object DestekDisi
if ($eski) {
    $eski | Select-Object Makine, Isletim, DestekBitis | Format-Table -AutoSize
    Write-Host "$($eski.Count) sunucu destek dışı." -ForegroundColor Red
} else {
    Write-Host "Yok." -ForegroundColor Green
}

Write-Host "== Diski dolmak üzere olanlar (>85%)" -ForegroundColor Cyan
$zenginlestirilmis | Where-Object { $_.CDoluYuzde -gt 85 } |
    Select-Object Makine, CDoluYuzde | Format-Table -AutoSize

if ($ulasilamayan) {
    Write-Host "Ulaşılamayan ($($ulasilamayan.Count)): $($ulasilamayan -join ', ')" -ForegroundColor Yellow
}

if ($CiktiCsv) {
    $zenginlestirilmis | Export-Csv $CiktiCsv -NoTypeInformation -Encoding UTF8
    Write-Host "CSV yazıldı: $CiktiCsv" -ForegroundColor Green
}
