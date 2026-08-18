<#
.SYNOPSIS
    Koşullu erişim ilkelerini ve kapsam boşluklarını çıkarır.

.DESCRIPTION
    Koşullu erişim zamanla katmanlanır: kimse hangi ilkenin kimi
    kapsadığını bilmez, en tehlikelisi de hiçbir ilkenin kapsamadığı
    hesaplardır. Bu betik ilkeleri, hariç tutulan hesapları ve rapor
    kipinde unutulmuş ilkeleri listeler.

    Değişiklik yapmaz.

.EXAMPLE
    .\entra-kosullu-erisim-envanteri.ps1

.NOTES
    bilgince.com — Hızlı Çözümler
    Microsoft.Graph.Identity.SignIns modülü ve Policy.Read.All izni gerekir.
#>

[CmdletBinding()]
param()

Connect-MgGraph -Scopes 'Policy.Read.All', 'Directory.Read.All' -NoWelcome

$ilkeler = Get-MgIdentityConditionalAccessPolicy -All

Write-Host "== İlkeler" -ForegroundColor Cyan
$ilkeler | ForEach-Object {
    [pscustomobject]@{
        Ad       = $_.DisplayName
        Durum    = $_.State
        Kapsam   = if ($_.Conditions.Users.IncludeUsers -contains 'All') { 'Tüm kullanıcılar' }
                   else { "$($_.Conditions.Users.IncludeUsers.Count) hedef" }
        HaricSayi = $_.Conditions.Users.ExcludeUsers.Count + $_.Conditions.Users.ExcludeGroups.Count
        Denetim  = ($_.GrantControls.BuiltInControls) -join ', '
    }
} | Sort-Object Durum, Ad | Format-Table -AutoSize

Write-Host "== Rapor kipinde unutulmuş ilkeler" -ForegroundColor Cyan
$rapor = $ilkeler | Where-Object { $_.State -eq 'enabledForReportingButNotEnforced' }
if ($rapor) {
    $rapor | Select-Object DisplayName, ModifiedDateTime | Format-Table -AutoSize
    Write-Host "Rapor kipi hiçbir şeyi engellemez; uzun süredir bu hâldeyse karar verilmemiş demektir." -ForegroundColor Yellow
} else {
    Write-Host "Yok." -ForegroundColor Green
}

Write-Host "== Kapalı ilkeler" -ForegroundColor Cyan
$ilkeler | Where-Object { $_.State -eq 'disabled' } | Select-Object DisplayName | Format-Table -AutoSize

Write-Host "== Hariç tutulan hesaplar (ilke başına)" -ForegroundColor Cyan
foreach ($i in $ilkeler | Where-Object { $_.Conditions.Users.ExcludeUsers.Count -gt 0 }) {
    Write-Host "  $($i.DisplayName):" -ForegroundColor White
    foreach ($k in $i.Conditions.Users.ExcludeUsers) {
        $ad = try { (Get-MgUser -UserId $k -ErrorAction Stop).UserPrincipalName } catch { $k }
        Write-Host "    - $ad"
    }
}

Write-Host ""
Write-Host "Acil durum (break-glass) hesabı dışındaki her istisnayı gerekçesiyle kayda geçirin." -ForegroundColor Yellow
