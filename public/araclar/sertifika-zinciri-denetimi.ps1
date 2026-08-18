<#
.SYNOPSIS
    Bir adresin sertifika zincirini ve süresini uçtan uca denetler.

.DESCRIPTION
    Sertifika hatalarının çoğu sertifikanın kendisinden değil eksik ara
    sertifikadan gelir: tarayıcıda çalışır, sunucuda ya da mobilde çalışmaz.
    Bu betik zinciri açar, her halkanın süresini gösterir, eksik ara
    sertifikayı ve zayıf imza algoritmasını işaretler.

    Değişiklik yapmaz.

.PARAMETER Adres
    Denetlenecek sunucu adı.

.PARAMETER Port
    Varsayılan 443.

.EXAMPLE
    .\sertifika-zinciri-denetimi.ps1 -Adres portal.sirket.com

.NOTES
    bilgince.com — Hızlı Çözümler
    Zincir doğrulaması çalıştığınız makinenin kök deposuna göre yapılır.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Adres,
    [int]$Port = 443
)

$istemci = New-Object System.Net.Sockets.TcpClient
try {
    $istemci.Connect($Adres, $Port)
} catch {
    Write-Error "Bağlanılamadı: $Adres port $Port"
    return
}

$akis = New-Object System.Net.Security.SslStream($istemci.GetStream(), $false, { $true })
$akis.AuthenticateAsClient($Adres)
$sertifika = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($akis.RemoteCertificate)

Write-Host "== Sunucu sertifikası" -ForegroundColor Cyan
[pscustomobject]@{
    Konu       = $sertifika.Subject
    Veren      = $sertifika.Issuer
    Baslangic  = $sertifika.NotBefore
    Bitis      = $sertifika.NotAfter
    KalanGun   = [int]($sertifika.NotAfter - (Get-Date)).TotalDays
    Algoritma  = $sertifika.SignatureAlgorithm.FriendlyName
    Protokol   = $akis.SslProtocol
} | Format-List

$sanUzanti = $sertifika.Extensions | Where-Object { $_.Oid.FriendlyName -eq 'Subject Alternative Name' }
if ($sanUzanti) {
    Write-Host "== Kapsanan adlar" -ForegroundColor Cyan
    $sanUzanti.Format($true)
}

Write-Host "== Zincir" -ForegroundColor Cyan
$zincir = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$zincir.ChainPolicy.RevocationMode = 'NoCheck'
$gecerli = $zincir.Build($sertifika)

$i = 0
foreach ($halka in $zincir.ChainElements) {
    $i++
    Write-Host ("  {0}. {1}" -f $i, $halka.Certificate.Subject)
    Write-Host ("     bitiş: {0} ({1} gün)" -f $halka.Certificate.NotAfter,
        [int]($halka.Certificate.NotAfter - (Get-Date)).TotalDays)
}

if (-not $gecerli) {
    Write-Host "== Zincir sorunları" -ForegroundColor Red
    foreach ($d in $zincir.ChainStatus) { Write-Host "  - $($d.StatusInformation.Trim())" }
    Write-Host "PartialChain görüyorsanız sunucu ara sertifikayı göndermiyordur." -ForegroundColor Yellow
} else {
    Write-Host "Zincir geçerli." -ForegroundColor Green
}

$akis.Close(); $istemci.Close()
