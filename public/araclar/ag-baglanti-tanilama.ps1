<#
.SYNOPSIS
    Bir hedefe giden yolu katman katman sınar.

.DESCRIPTION
    "Bağlanamıyorum" çağrısında sorun altı ayrı yerde olabilir: ad
    çözümleme, yönlendirme, güvenlik duvarı, TLS, kimlik, uygulama. Bu
    betik hepsini sırayla dener ve ilk kırılan halkayı söyler.

    Değişiklik yapmaz.

.PARAMETER Hedef
    Sunucu adı ya da adresi.

.PARAMETER Port
    Sınanacak TCP portu. Varsayılan 443.

.EXAMPLE
    .\ag-baglanti-tanilama.ps1 -Hedef portal.sirket.com -Port 443

.NOTES
    bilgince.com — Hızlı Çözümler
    ICMP kapalı olabilir; ping başarısızlığı tek başına sorun anlamına gelmez.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Hedef,
    [int]$Port = 443
)

function Adim([string]$ad, [scriptblock]$is) {
    Write-Host "== $ad" -ForegroundColor Cyan
    try { & $is } catch { Write-Host "  HATA: $($_.Exception.Message)" -ForegroundColor Red }
}

Adim "1. Yerel ağ yapılandırması" {
    Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' } |
        Select-Object InterfaceAlias, IPv4Address,
            @{ n = 'AgGecidi'; e = { $_.IPv4DefaultGateway.NextHop } },
            @{ n = 'DNS'; e = { ($_.DNSServer | Where-Object AddressFamily -eq 2).ServerAddresses -join ', ' } } |
        Format-List
}

Adim "2. Ad çözümleme" {
    $c = Resolve-DnsName $Hedef -ErrorAction Stop
    $c | Select-Object Name, Type, IPAddress, NameHost | Format-Table -AutoSize
}

Adim "3. ICMP (kapalı olabilir, tek başına kanıt değil)" {
    $p = Test-Connection $Hedef -Count 2 -ErrorAction SilentlyContinue
    if ($p) { Write-Host "  yanıt var, ortalama $([int](($p | Measure-Object ResponseTime -Average).Average)) ms" -ForegroundColor Green }
    else { Write-Host "  yanıt yok" -ForegroundColor Yellow }
}

Adim "4. TCP $Port" {
    $t = Test-NetConnection $Hedef -Port $Port -WarningAction SilentlyContinue
    if ($t.TcpTestSucceeded) {
        Write-Host "  port açık" -ForegroundColor Green
    } else {
        Write-Host "  port kapalı ya da filtreleniyor" -ForegroundColor Red
        Write-Host "  yol izi:" -ForegroundColor Yellow
        Test-NetConnection $Hedef -TraceRoute -WarningAction SilentlyContinue |
            Select-Object -ExpandProperty TraceRoute
    }
}

if ($Port -eq 443) {
    Adim "5. TLS el sıkışması" {
        $istemci = New-Object System.Net.Sockets.TcpClient
        $istemci.Connect($Hedef, 443)
        $akis = New-Object System.Net.Security.SslStream($istemci.GetStream(), $false, { $true })
        $akis.AuthenticateAsClient($Hedef)
        $s = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($akis.RemoteCertificate)
        Write-Host "  protokol: $($akis.SslProtocol)" -ForegroundColor Green
        Write-Host "  sertifika bitiş: $($s.NotAfter) ($([int]($s.NotAfter - (Get-Date)).TotalDays) gün)"
        $akis.Close(); $istemci.Close()
    }
}

Adim "6. Vekil sunucu ayarı" {
    $v = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
    if ($v.ProxyEnable -eq 1) { Write-Host "  vekil açık: $($v.ProxyServer)" -ForegroundColor Yellow }
    else { Write-Host "  vekil kapalı" }
}
