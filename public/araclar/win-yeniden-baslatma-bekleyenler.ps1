<#
.SYNOPSIS
    Güncellemesi bitmiş ama yeniden başlatılmamış makineleri bulur.

.DESCRIPTION
    Yarım kalmış güncelleme en sinsi durumdur: yama yüklü görünür, koruma
    devrede değildir. Betik yeniden başlatma bekleyen makineleri bulur ve
    sebebini (güncelleme, bileşen kurulumu, ad değişikliği) söyler.

    Değişiklik yapmaz.

.PARAMETER Bilgisayarlar
    Taranacak makineler. Verilmezse AD'deki etkin sunucular.

.EXAMPLE
    .\win-yeniden-baslatma-bekleyenler.ps1

.NOTES
    bilgince.com — Hızlı Çözümler
    WinRM gerekir. Ulaşılamayan makineler ayrı listelenir.
#>

[CmdletBinding()]
param([string[]]$Bilgisayarlar)

if (-not $Bilgisayarlar) {
    Import-Module ActiveDirectory -ErrorAction Stop
    $Bilgisayarlar = (Get-ADComputer -Filter { Enabled -eq $true -and OperatingSystem -like '*Server*' }).Name
}

$ulasilamayan = @()
$sonuc = foreach ($m in $Bilgisayarlar) {
    try {
        Invoke-Command -ComputerName $m -ErrorAction Stop -ScriptBlock {
            $sebepler = @()
            if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
                $sebepler += 'Windows Update'
            }
            if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
                $sebepler += 'Bileşen kurulumu'
            }
            $ad = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name ComputerName
            $hedef = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Name ComputerName
            if ($ad.ComputerName -ne $hedef.ComputerName) { $sebepler += 'Ad değişikliği' }

            [pscustomobject]@{
                Makine    = $env:COMPUTERNAME
                Bekliyor  = $sebepler.Count -gt 0
                Sebep     = $sebepler -join ', '
                SonAcilis = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
            }
        }
    } catch {
        $ulasilamayan += $m
    }
}

Write-Host "== Yeniden başlatma bekleyenler" -ForegroundColor Cyan
$bekleyen = $sonuc | Where-Object Bekliyor
if ($bekleyen) {
    $bekleyen | Select-Object Makine, Sebep,
        @{ n = 'AcilisUzerinden'; e = { "$([int]((Get-Date) - $_.SonAcilis).TotalDays) gün" } } |
        Format-Table -AutoSize
    Write-Host "$($bekleyen.Count) makine yarım güncelleme taşıyor." -ForegroundColor Yellow
} else {
    Write-Host "Bekleyen yok." -ForegroundColor Green
}

Write-Host "== En uzun süredir açık kalan makineler" -ForegroundColor Cyan
$sonuc | Sort-Object SonAcilis | Select-Object -First 10 Makine,
    @{ n = 'GunOnce'; e = { [int]((Get-Date) - $_.SonAcilis).TotalDays } } | Format-Table -AutoSize

if ($ulasilamayan) {
    Write-Host "Ulaşılamayan ($($ulasilamayan.Count)): $($ulasilamayan -join ', ')" -ForegroundColor Yellow
}
