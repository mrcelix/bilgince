<#
.SYNOPSIS
    Şüpheli posta yönlendirme ve gelen kutusu kurallarını tarar.

.DESCRIPTION
    Ele geçirilmiş bir hesabın ilk işareti genelde sessiz bir kuraldır:
    gelen postayı dışarı yönlendiren, belirli anahtar kelimeleri okundu
    işaretleyip silen ya da klasöre gizleyen. Bu betik hem posta kutusu
    düzeyindeki yönlendirmeyi hem gelen kutusu kurallarını tarar.

    Değişiklik yapmaz.

.EXAMPLE
    .\m365-posta-kural-denetimi.ps1

.NOTES
    bilgince.com — Hızlı Çözümler
    ExchangeOnlineManagement modülü gerekir. Büyük kiracılarda uzun sürer.
#>

[CmdletBinding()]
param()

Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-ExchangeOnline -ShowBanner:$false

$kabul = (Get-AcceptedDomain).DomainName

Write-Host "== Posta kutusu düzeyinde dış yönlendirme" -ForegroundColor Cyan
$yonlendiren = Get-Mailbox -ResultSize Unlimited |
    Where-Object { $_.ForwardingSmtpAddress -or $_.ForwardingAddress }
if ($yonlendiren) {
    $yonlendiren | Select-Object DisplayName, PrimarySmtpAddress,
        ForwardingSmtpAddress, DeliverToMailboxAndForward | Format-Table -AutoSize
} else {
    Write-Host "Yok." -ForegroundColor Green
}

Write-Host "== Şüpheli gelen kutusu kuralları" -ForegroundColor Cyan
$supheli = foreach ($kutu in Get-Mailbox -ResultSize Unlimited) {
    $kurallar = Get-InboxRule -Mailbox $kutu.PrimarySmtpAddress -ErrorAction SilentlyContinue
    foreach ($k in $kurallar) {
        $disari = $false
        foreach ($hedef in @($k.ForwardTo) + @($k.RedirectTo) + @($k.ForwardAsAttachmentTo)) {
            if ($hedef -and ($kabul | Where-Object { $hedef -like "*$_*" }).Count -eq 0) { $disari = $true }
        }
        # Sil + okundu işaretle birlikteyse gizleme amacı taşır
        $gizleme = $k.DeleteMessage -and $k.MarkAsRead
        if ($disari -or $gizleme) {
            [pscustomobject]@{
                Kutu    = $kutu.PrimarySmtpAddress
                Kural   = $k.Name
                Etkin   = $k.Enabled
                DisHedef = ($k.ForwardTo + $k.RedirectTo) -join '; '
                Siliyor = $k.DeleteMessage
            }
        }
    }
}

if ($supheli) {
    $supheli | Format-Table -AutoSize
    Write-Host "$($supheli.Count) şüpheli kural. Kullanıcıyla doğrulamadan silmeyin." -ForegroundColor Red
} else {
    Write-Host "Şüpheli kural yok." -ForegroundColor Green
}
