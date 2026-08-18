<#
.SYNOPSIS
    Atanmış ama kullanılmayan Microsoft 365 lisanslarını bulur.

.DESCRIPTION
    Lisans maliyeti sessizce büyür: ayrılan çalışanın hesabı devre dışı
    bırakılır ama lisansı sökülmez, proje hesapları unutulur. Bu betik
    lisanslı hesapları son oturum açma tarihine göre sıralar ve devre dışı
    olduğu hâlde lisans taşıyanları ayrı listeler.

    Değişiklik yapmaz.

.PARAMETER GunSayisi
    Kaç gündür oturum açmayanlar raporlansın. Varsayılan 90.

.EXAMPLE
    .\m365-lisans-envanteri.ps1 -GunSayisi 60

.NOTES
    bilgince.com — Hızlı Çözümler
    Microsoft.Graph modülü ve Entra ID P1 gerekir (SignInActivity için).
#>

[CmdletBinding()]
param([int]$GunSayisi = 90)

if (-not (Get-Module -ListAvailable Microsoft.Graph.Users)) {
    Write-Error "Microsoft.Graph modülü yok: Install-Module Microsoft.Graph -Scope CurrentUser"
    return
}

Connect-MgGraph -Scopes 'User.Read.All', 'AuditLog.Read.All', 'Organization.Read.All' -NoWelcome
$sinir = (Get-Date).AddDays(-$GunSayisi)

Write-Host "== Kiralanan ve atanan lisanslar" -ForegroundColor Cyan
Get-MgSubscribedSku | ForEach-Object {
    [pscustomobject]@{
        Urun     = $_.SkuPartNumber
        Alinan   = $_.PrepaidUnits.Enabled
        Atanan   = $_.ConsumedUnits
        Bosta    = $_.PrepaidUnits.Enabled - $_.ConsumedUnits
    }
} | Sort-Object Bosta -Descending | Format-Table -AutoSize

$kullanicilar = Get-MgUser -All -Property DisplayName, UserPrincipalName, AccountEnabled,
    SignInActivity, AssignedLicenses | Where-Object { $_.AssignedLicenses.Count -gt 0 }

Write-Host "== Devre dışı ama lisanslı hesaplar" -ForegroundColor Cyan
$kapali = $kullanicilar | Where-Object { -not $_.AccountEnabled }
if ($kapali) {
    $kapali | Select-Object DisplayName, UserPrincipalName,
        @{ n = 'LisansSayisi'; e = { $_.AssignedLicenses.Count } } | Format-Table -AutoSize
    Write-Host "$($kapali.Count) devre dışı hesap hâlâ lisans tüketiyor." -ForegroundColor Yellow
} else {
    Write-Host "Yok." -ForegroundColor Green
}

Write-Host "== $GunSayisi gündür oturum açmayanlar" -ForegroundColor Cyan
$kullanicilar | Where-Object {
    $_.AccountEnabled -and $_.SignInActivity.LastSignInDateTime -lt $sinir
} | Select-Object DisplayName, UserPrincipalName,
    @{ n = 'SonGiris'; e = { $_.SignInActivity.LastSignInDateTime } } |
    Sort-Object SonGiris | Format-Table -AutoSize

Write-Host "Hizmet hesapları hiç oturum açmaz; lisans sökmeden önce sahibini doğrulayın." -ForegroundColor Yellow
