<#
.SYNOPSIS
    SharePoint ve OneDrive dış paylaşımlarını raporlar.

.DESCRIPTION
    "Herkese açık bağlantı" bir kez oluşturulur ve yıllarca yaşar. Bu
    betik site düzeyindeki dış paylaşım ayarlarını, anonim bağlantı
    politikasını ve süresi dolmayan paylaşımları listeler.

    Değişiklik yapmaz.

.PARAMETER Kiraci
    Kiracı adı (sirket.sharepoint.com içindeki "sirket" kısmı).

.EXAMPLE
    .\m365-paylasim-denetimi.ps1 -Kiraci sirket

.NOTES
    bilgince.com — Hızlı Çözümler
    Microsoft.Online.SharePoint.PowerShell modülü ve SharePoint yöneticisi gerekir.
#>

[CmdletBinding()]
param([Parameter(Mandatory)][string]$Kiraci)

Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
Connect-SPOService -Url "https://$Kiraci-admin.sharepoint.com"

Write-Host "== Kiracı düzeyinde paylaşım politikası" -ForegroundColor Cyan
Get-SPOTenant | Select-Object SharingCapability, DefaultSharingLinkType,
    RequireAnonymousLinksExpireInDays, FileAnonymousLinkType, FolderAnonymousLinkType |
    Format-List

Write-Host "== Dış paylaşıma açık siteler" -ForegroundColor Cyan
$siteler = Get-SPOSite -Limit All
$acik = $siteler | Where-Object { $_.SharingCapability -ne 'Disabled' }
$acik | Select-Object Url, SharingCapability, StorageUsageCurrent, LastContentModifiedDate |
    Sort-Object LastContentModifiedDate | Format-Table -AutoSize

Write-Host "Toplam site: $($siteler.Count) | Dış paylaşıma açık: $($acik.Count)" -ForegroundColor Yellow

Write-Host "== Uzun süredir dokunulmamış ama paylaşıma açık siteler" -ForegroundColor Cyan
$sinir = (Get-Date).AddDays(-180)
$acik | Where-Object { $_.LastContentModifiedDate -lt $sinir } |
    Select-Object Url, LastContentModifiedDate | Format-Table -AutoSize

Write-Host "Anonim bağlantıların süresi tanımlı değilse RequireAnonymousLinksExpireInDays ayarlayın." -ForegroundColor Yellow
