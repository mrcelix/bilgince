<#
.SYNOPSIS
    Makinelerdeki yerel yönetici üyeliklerini envanterler.

.DESCRIPTION
    Yerel yönetici hakkı en çok sızan haktır: bir kez verilir, kimse geri
    almaz. Bu betik hedef makinelerdeki yerel Administrators grubunu okur,
    etki alanı dışındaki hesapları ayırır ve beklenmeyen üyeleri işaretler.

    Değişiklik yapmaz.

.PARAMETER Bilgisayarlar
    Taranacak makineler. Verilmezse AD'deki etkin sunucular.

.PARAMETER Beklenen
    Normal sayılan üyeler; raporda işaretlenmez.

.EXAMPLE
    .\win-yerel-yonetici-denetimi.ps1 -Beklenen "SIRKET\Domain Admins","Administrator"

.NOTES
    bilgince.com — Hızlı Çözümler
    WinRM gerekir. Erişilemeyen makineler ayrı listelenir.
#>

[CmdletBinding()]
param(
    [string[]]$Bilgisayarlar,
    [string[]]$Beklenen = @('Administrator', 'Domain Admins')
)

if (-not $Bilgisayarlar) {
    Import-Module ActiveDirectory -ErrorAction Stop
    $Bilgisayarlar = (Get-ADComputer -Filter { Enabled -eq $true -and OperatingSystem -like '*Server*' }).Name
}

Write-Host "$($Bilgisayarlar.Count) makine taranıyor..." -ForegroundColor Cyan

$ulasilamayan = @()
$bulgular = foreach ($m in $Bilgisayarlar) {
    try {
        $uyeler = Invoke-Command -ComputerName $m -ErrorAction Stop -ScriptBlock {
            Get-LocalGroupMember -Group 'Administrators' | Select-Object Name, PrincipalSource
        }
        foreach ($u in $uyeler) {
            $kisaAd = ($u.Name -split '\\')[-1]
            [pscustomobject]@{
                Makine   = $m
                Uye      = $u.Name
                Kaynak   = $u.PrincipalSource
                Beklenen = [bool]($Beklenen | Where-Object { $kisaAd -eq $_ -or $u.Name -eq $_ })
            }
        }
    } catch {
        $ulasilamayan += $m
    }
}

Write-Host "== Beklenmeyen yerel yönetici üyeleri" -ForegroundColor Cyan
$beklenmeyen = $bulgular | Where-Object { -not $_.Beklenen }
if ($beklenmeyen) {
    $beklenmeyen | Sort-Object Makine | Format-Table Makine, Uye, Kaynak -AutoSize
    Write-Host "$($beklenmeyen.Count) beklenmeyen üyelik." -ForegroundColor Yellow
} else {
    Write-Host "Yok." -ForegroundColor Green
}

Write-Host "== En çok yerel yönetici taşıyan makineler" -ForegroundColor Cyan
$bulgular | Group-Object Makine | Sort-Object Count -Descending |
    Select-Object -First 10 Count, Name | Format-Table -AutoSize

if ($ulasilamayan) {
    Write-Host "== Ulaşılamayan makineler ($($ulasilamayan.Count))" -ForegroundColor Yellow
    $ulasilamayan -join ', '
    Write-Host "Bunlar taranmadı; envanteri tam saymayın." -ForegroundColor Yellow
}
