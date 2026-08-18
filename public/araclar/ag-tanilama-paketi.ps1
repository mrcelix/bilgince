<#
.SYNOPSIS
    "İnternet yok" şikâyetinde katman katman ilerleyen tek sayfalık ağ raporu.

.DESCRIPTION
    Sırayı bozmadan ilerler: fiziksel bağlantı → IP yapılandırması → ağ geçidi →
    DNS → dış erişim → proxy → MTU. Her adımda nerede koptuğunu söyler, çünkü
    "internet yok" cümlesinin altında yedi ayrı arıza vardır.

    Çıktıyı destek talebine eklemek için -Dosya ile kaydedin.

.PARAMETER Hedef
    Dış erişim testi için kullanılacak adres. Varsayılan www.google.com

.PARAMETER Dosya
    Raporu bu yola metin olarak da yazar.

.EXAMPLE
    .\ag-tanilama-paketi.ps1
    .\ag-tanilama-paketi.ps1 -Dosya "$env:USERPROFILE\Desktop\ag-raporu.txt"

.NOTES
    bilgince.com — Hızlı Çözümler
    Değişiklik yapmaz.
#>

[CmdletBinding()]
param(
    [string]$Hedef = 'www.google.com',
    [string]$Dosya
)

$ErrorActionPreference = 'SilentlyContinue'
$rapor = [System.Collections.Generic.List[string]]::new()

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
    $rapor.Add($Metin)
}

Yaz "=== Ağ tanılama — $env:COMPUTERNAME — $(Get-Date -f 'dd.MM.yyyy HH:mm') ===" Baslik

# ------------------------------------------------------------- 1. arayüz
Yaz "`n--- 1. Fiziksel bağlantı ---" Baslik
$arayuzler = Get-NetAdapter | Where-Object Status -eq 'Up'
if (-not $arayuzler) {
    Yaz 'Bağlı hiçbir ağ arayüzü yok. Kablo, Wi-Fi anahtarı ya da sürücü.' Hata
    return
}
$arayuzler | Select-Object Name, InterfaceDescription, LinkSpeed | Format-Table -AutoSize |
    Out-String | ForEach-Object { $rapor.Add($_); Write-Host $_ }

# ----------------------------------------------------------------- 2. IP
Yaz "--- 2. IP yapılandırması ---" Baslik
$ipler = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' }
foreach ($ip in $ipler) {
    $adres = $ip.IPv4Address.IPAddress
    Yaz "$($ip.InterfaceAlias): $adres  ağ geçidi: $($ip.IPv4DefaultGateway.NextHop)"
    if ($adres -like '169.254.*') {
        Yaz '  169.254 adresi = DHCP sunucusundan cevap alınamamış (APIPA). Sorun burada.' Hata
    }
    if (-not $ip.IPv4DefaultGateway) {
        Yaz '  Varsayılan ağ geçidi yok — yerel ağ çalışır, internet çalışmaz.' Hata
    }
}

# --------------------------------------------------------- 3. ağ geçidi testi
Yaz "`n--- 3. Ağ geçidi ---" Baslik
$gw = ($ipler | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4DefaultGateway.NextHop
if ($gw) {
    $gwTest = Test-Connection $gw -Count 2 -Quiet
    Yaz "Ağ geçidi $gw : $(if ($gwTest) { 'erişilebilir' } else { 'ERİŞİLEMİYOR' })" $(if ($gwTest) { 'Iyi' } else { 'Hata' })
    if (-not $gwTest) { Yaz '  Anahtar, kablolama ya da VLAN sorunu. Bu noktadan sonrası boşuna.' Uyari }
}

# ----------------------------------------------------------------- 4. DNS
Yaz "`n--- 4. DNS ---" Baslik
$dnsSunuculari = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses }).ServerAddresses | Select-Object -Unique
Yaz "Tanımlı DNS sunucuları: $($dnsSunuculari -join ', ')"

$dnsSonuc = Resolve-DnsName $Hedef -Type A -ErrorAction SilentlyContinue | Select-Object -First 1
if ($dnsSonuc) {
    Yaz "$Hedef çözüldü: $($dnsSonuc.IPAddress)" Iyi
} else {
    Yaz "$Hedef ÇÖZÜLEMEDİ." Hata
    $dogrudan = Resolve-DnsName $Hedef -Server 1.1.1.1 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($dogrudan) {
        Yaz '  Dış DNS (1.1.1.1) çözüyor: sorun sizin DNS sunucunuzda.' Uyari
    } else {
        Yaz '  Dış DNS de çözemedi: 53. port kapalı ya da internet çıkışı yok.' Uyari
    }
}

# --------------------------------------------------------- 5. dış erişim
Yaz "`n--- 5. Dış erişim ---" Baslik
foreach ($port in 443, 80) {
    $t = Test-NetConnection $Hedef -Port $port -WarningAction SilentlyContinue
    Yaz "$Hedef :$port  $(if ($t.TcpTestSucceeded) { 'açık' } else { 'KAPALI' })" $(if ($t.TcpTestSucceeded) { 'Iyi' } else { 'Hata' })
}
$icmp = Test-Connection 1.1.1.1 -Count 2 -Quiet
Yaz "1.1.1.1 ping: $(if ($icmp) { 'cevap var' } else { 'cevap yok (ICMP engelli olabilir)' })"

# -------------------------------------------------------------- 6. proxy
Yaz "`n--- 6. Proxy ---" Baslik
$proxy = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
if ($proxy.ProxyEnable -eq 1) {
    Yaz "Proxy AÇIK: $($proxy.ProxyServer)" Uyari
    Yaz '  Proxy erişilemezse tarayıcı çalışmaz ama ping çalışır — belirtinin klasik sebebi.' Bilgi
} else {
    Yaz 'Proxy tanımlı değil.' Iyi
}
$winhttp = netsh winhttp show proxy
$rapor.Add(($winhttp | Out-String))
$winhttp | Select-Object -Skip 2 | ForEach-Object { if ($_.Trim()) { Yaz "  $($_.Trim())" } }

# ---------------------------------------------------------------- 7. MTU
Yaz "`n--- 7. MTU ---" Baslik
Get-NetIPInterface -AddressFamily IPv4 | Where-Object ConnectionState -eq 'Connected' |
    Select-Object InterfaceAlias, NlMtu, InterfaceMetric | Format-Table -AutoSize |
    Out-String | ForEach-Object { $rapor.Add($_); Write-Host $_ }

$parcalanma = ping -f -l 1472 -n 1 $Hedef 2>&1 | Out-String
if ($parcalanma -match 'gerekiyor|needs to be fragmented') {
    Yaz '1472 baytlık paket geçmiyor: yolda MTU 1500''ün altında (VPN, PPPoE, tünel).' Uyari
    Yaz '  mtu-bulma komutuyla gerçek değeri ikili aramayla bulun.' Bilgi
} else {
    Yaz 'MTU 1500 yolunda sorun görünmüyor.' Iyi
}

# ------------------------------------------------------------------ özet
Yaz "`n--- Özet: nerede kopuyor ---" Baslik
Yaz 'IP yok / 169.254        → DHCP'
Yaz 'Ağ geçidi cevapsız      → anahtar, kablo, VLAN'
Yaz 'DNS çözmüyor            → DNS sunucusu ya da 53. port'
Yaz 'DNS çözüyor, 443 kapalı → güvenlik duvarı ya da içerik süzme'
Yaz 'Her şey açık ama tarayıcı boş → proxy'
Yaz 'Bazı siteler açılıyor bazıları takılıyor → MTU'

if ($Dosya) {
    $rapor -join "`r`n" | Out-File -FilePath $Dosya -Encoding utf8
    Write-Host "`nRapor kaydedildi: $Dosya" -ForegroundColor Green
}
