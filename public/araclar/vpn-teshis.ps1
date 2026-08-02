<#
.SYNOPSIS
    "VPN bağlandı ama iç kaynağa erişemiyorum" durumunu teşhis eder.

.DESCRIPTION
    Bağlantı kurulduğu hâlde erişim olmamasının dört tipik sebebini sırayla
    kontrol eder: yönlendirme tablosunda hedef ağın olmaması, DNS'in hâlâ yerel
    çözümleyiciyi kullanması, bölünmüş tünel kapsamının dar olması ve isim
    çözümlemesinin doğru ama erişimin engelli olması.

    Hiçbir değişiklik yapmaz — yalnızca rapor üretir.

.PARAMETER HedefAg
    Erişmeye çalıştığınız iç ağ. Örn: 10.10.0.0/16

.PARAMETER HedefSunucu
    Test edilecek iç sunucu adı. Örn: dosya01.sirket.local

.PARAMETER Port
    Test edilecek TCP portu. Varsayılan 445 (dosya paylaşımı).

.EXAMPLE
    .\vpn-teshis.ps1 -HedefAg 10.10.0.0/16 -HedefSunucu dosya01.sirket.local

.NOTES
    bilgince.com — Hızlı Çözümler
#>

[CmdletBinding()]
param(
    [string]$HedefAg,
    [string]$HedefSunucu,
    [int]$Port = 445
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

Yaz "=== VPN teşhis — $(Get-Date -f 'HH:mm:ss') ===" Baslik

# ------------------------------------------------------------ 1. VPN arayüzü
Yaz "`n--- 1. VPN arayüzü ---" Baslik

$vpn = Get-NetAdapter | Where-Object {
    $_.Status -eq 'Up' -and ($_.InterfaceDescription -match 'VPN|TAP|WAN Miniport|Wintun|OpenVPN|AnyConnect|GlobalProtect|FortiClient')
}

if (-not $vpn) {
    Yaz 'VPN arayüzü bulunamadı. Bağlantı gerçekten kurulu mu?' Hata
    Get-NetAdapter | Where-Object Status -eq 'Up' |
        Select-Object Name, InterfaceDescription | Format-Table -AutoSize
    return
}

$vpn | Select-Object Name, InterfaceDescription, LinkSpeed | Format-Table -AutoSize
$vpnIndex = $vpn[0].ifIndex

$vpnIp = Get-NetIPAddress -InterfaceIndex $vpnIndex -AddressFamily IPv4
Yaz "VPN adresi: $($vpnIp.IPAddress)" $(if ($vpnIp) { 'Iyi' } else { 'Hata' })

# ------------------------------------------------------- 2. yönlendirme tablosu
Yaz "`n--- 2. Yönlendirme ---" Baslik

$rotalar = Get-NetRoute -InterfaceIndex $vpnIndex -AddressFamily IPv4 |
    Sort-Object -Property @{ E = { [int]($_.DestinationPrefix -split '/')[1] } } -Descending

if ($rotalar) {
    $rotalar | Select-Object DestinationPrefix, NextHop, RouteMetric | Format-Table -AutoSize
} else {
    Yaz 'VPN arayüzü üzerinden hiç rota yok — tünel kurulmuş ama trafik yönlendirilmiyor.' Hata
}

$tamTunel = $rotalar | Where-Object DestinationPrefix -eq '0.0.0.0/0'
Yaz ("Tünel türü: {0}" -f $(if ($tamTunel) { 'TAM TÜNEL (tüm trafik VPN''den)' } else { 'BÖLÜNMÜŞ TÜNEL (yalnızca belirli ağlar)' }))

if ($HedefAg) {
    $hedefIp = ($HedefAg -split '/')[0]
    $secilen = Find-NetRoute -RemoteIPAddress $hedefIp -ErrorAction SilentlyContinue
    if ($secilen) {
        $cikis = $secilen[1].InterfaceIndex
        if ($cikis -eq $vpnIndex) {
            Yaz "$HedefAg trafiği VPN üzerinden gidiyor." Iyi
        } else {
            $ad = (Get-NetAdapter -InterfaceIndex $cikis).Name
            Yaz "$HedefAg trafiği VPN'den DEĞİL, '$ad' üzerinden gidiyor." Hata
            Yaz 'Sebep: bölünmüş tünel kapsamına bu ağ dahil edilmemiş.' Uyari
        }
    }
}

# ----------------------------------------------------------------- 3. DNS
Yaz "`n--- 3. DNS ---" Baslik

Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object { $_.ServerAddresses } |
    Select-Object InterfaceAlias, @{ n = 'Sunucular'; e = { $_.ServerAddresses -join ', ' } } |
    Format-Table -AutoSize

$vpnDns = (Get-DnsClientServerAddress -InterfaceIndex $vpnIndex -AddressFamily IPv4).ServerAddresses
if (-not $vpnDns) {
    Yaz 'VPN arayüzüne DNS sunucusu atanmamış — iç isimler çözülemez.' Hata
} else {
    Yaz "VPN DNS: $($vpnDns -join ', ')" Iyi
}

# arayüz ölçütü, hangi DNS'in önce sorulacağını belirler
$olcut = Get-NetIPInterface -AddressFamily IPv4 |
    Where-Object ConnectionState -eq 'Connected' |
    Select-Object InterfaceAlias, InterfaceMetric, @{n='OtomatikOlcut';e={$_.AutomaticMetric}} |
    Sort-Object InterfaceMetric
$olcut | Format-Table -AutoSize
Yaz 'Düşük ölçütlü arayüzün DNS''i önce sorulur. VPN üstte değilse iç isimler yerel DNS''e gider.' Bilgi

# ------------------------------------------------------------ 4. uçtan uca
if ($HedefSunucu) {
    Yaz "`n--- 4. Hedef testi: $HedefSunucu ---" Baslik

    $coz = Resolve-DnsName $HedefSunucu -ErrorAction SilentlyContinue |
        Where-Object Type -eq 'A' | Select-Object -First 1
    if ($coz) {
        Yaz "İsim çözüldü: $($coz.IPAddress)" Iyi
    } else {
        Yaz 'İsim çözülemedi — DNS sorunu (yukarıdaki 3. bölüme bakın).' Hata
    }

    $tcp = Test-NetConnection -ComputerName $HedefSunucu -Port $Port -WarningAction SilentlyContinue
    if ($tcp.TcpTestSucceeded) {
        Yaz "TCP/$Port erişimi başarılı — VPN çalışıyor." Iyi
    } else {
        Yaz "TCP/$Port erişilemedi." Hata
        if ($coz) {
            Yaz 'İsim çözülüyor ama porta erişilemiyor: güvenlik duvarı ya da sunucu tarafı kısıtlaması.' Uyari
        }
    }

    Yaz "`nYol izi:"
    Test-NetConnection -ComputerName $HedefSunucu -TraceRoute -WarningAction SilentlyContinue |
        Select-Object -ExpandProperty TraceRoute | ForEach-Object { Yaz "  $_" }
}

Yaz "`n--- Özet ---" Baslik
Yaz 'Rota yoksa   → bölünmüş tünel kapsamını genişletin (VPN yöneticisi)'
Yaz 'DNS yoksa    → VPN profiline iç DNS sunucusu tanımlanmalı'
Yaz 'İsim çözülüp port kapalıysa → güvenlik duvarı kuralı'
Yaz 'Hepsi iyi ama erişim yoksa  → uygulama tarafı (kimlik, sertifika, izin)'
