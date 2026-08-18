<#
.SYNOPSIS
    İç DNS altyapısının sağlığını ve en sık yapılan yapılandırma hatalarını
    denetler.

.DESCRIPTION
    DNS, Active Directory'nin görünmez bel kemiğidir: bozulduğunda belirtiler
    DNS'e benzemez (oturum açılmıyor, paylaşım gelmiyor, ilke uygulanmıyor).
    Bu betik sırayla bakar: istemci DNS ayarları, sunucu rolü, bölgeler,
    ileticiler, kök ipuçları, kayıt temizleme (scavenging), DC kayıtlarının
    varlığı ve çözümleme sınamaları.

    Değişiklik yapmaz.

.PARAMETER Sunucu
    Denetlenecek DNS sunucusu. Verilmezse yerel makine.

.PARAMETER Alan
    Sınanacak etki alanı. Verilmezse makinenin etki alanı.

.EXAMPLE
    .\dns-saglik-kontrol.ps1
    .\dns-saglik-kontrol.ps1 -Sunucu dc01 -Alan sirket.local

.NOTES
    bilgince.com — Hızlı Çözümler
    Sunucu tarafı kontroller için DnsServer modülü (RSAT) gerekir.
#>

[CmdletBinding()]
param(
    [string]$Sunucu = $env:COMPUTERNAME,
    [string]$Alan
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

if (-not $Alan) { $Alan = (Get-CimInstance Win32_ComputerSystem).Domain }

Yaz "=== DNS sağlık kontrolü — $Sunucu / $Alan ===" Baslik

# ------------------------------------------------------------ 1. istemci
Yaz "`n--- 1. İstemci DNS ayarları ---" Baslik
$arayuzler = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses }
$arayuzler | Select-Object InterfaceAlias, @{n='Sunucular';e={$_.ServerAddresses -join ', '}} | Format-Table -AutoSize

$dis = $arayuzler.ServerAddresses | Where-Object { $_ -match '^(8\.8\.|1\.1\.1\.|9\.9\.9\.|208\.67\.)' }
if ($dis) {
    Yaz "İstemcide dış DNS tanımlı: $($dis -join ', ')" Hata
    Yaz 'Etki alanı üyesi makinelerde DNS yalnızca iç sunucuları göstermelidir. Dış DNS, AD kayıtlarını çözemez;' Uyari
    Yaz 'belirti "bazen çalışıyor" biçiminde görünür çünkü sıra bazen iç sunucuya düşer.' Uyari
} else {
    Yaz 'İstemci yalnızca iç DNS sunucularını kullanıyor.' Iyi
}

# -------------------------------------------------------------- 2. sunucu
Yaz "`n--- 2. Sunucu rolü ---" Baslik
if (-not (Get-Module -ListAvailable -Name DnsServer)) {
    Yaz 'DnsServer modülü yok; sunucu tarafı kontroller atlanıyor (RSAT kurun).' Uyari
} else {
    Import-Module DnsServer

    $bolgeler = Get-DnsServerZone -ComputerName $Sunucu
    if ($bolgeler) {
        $bolgeler | Select-Object ZoneName, ZoneType, IsDsIntegrated, DynamicUpdate | Format-Table -AutoSize

        $adBolge = $bolgeler | Where-Object ZoneName -eq $Alan
        if ($adBolge) {
            if (-not $adBolge.IsDsIntegrated) {
                Yaz "$Alan bölgesi dizin bütünleşik değil — çoğaltma dosya kopyalamayla yapılıyor." Uyari
            }
            if ($adBolge.DynamicUpdate -ne 'Secure') {
                Yaz "Dinamik güncelleme: $($adBolge.DynamicUpdate) — 'Secure' olmalı." Uyari
                Yaz 'Güvensiz güncelleme, kimliği doğrulanmamış makinelerin kayıt yazmasına izin verir.' Bilgi
            } else {
                Yaz 'Dinamik güncelleme güvenli kipte.' Iyi
            }
        }

        # ters bölge: yokluğu teşhisi zorlaştırır
        $ters = $bolgeler | Where-Object ZoneName -like '*in-addr.arpa'
        Yaz "Ters arama bölgesi: $(if ($ters) { "$($ters.Count) adet" } else { 'YOK' })" $(if ($ters) { 'Iyi' } else { 'Uyari' })
        if (-not $ters) { Yaz 'Ters bölge olmadan IP''den ada çözümleme yapılamaz; günlük analizini zorlaştırır.' Bilgi }
    }

    # ------------------------------------------------------------ ileticiler
    Yaz "`n--- 3. İleticiler ve kök ipuçları ---" Baslik
    $ileticiler = Get-DnsServerForwarder -ComputerName $Sunucu
    if ($ileticiler.IPAddress) {
        Yaz "İleticiler: $($ileticiler.IPAddress -join ', ')" Iyi
        foreach ($ip in $ileticiler.IPAddress) {
            $t = Test-NetConnection $ip.IPAddressToString -Port 53 -WarningAction SilentlyContinue
            Yaz ("  {0} :53 → {1}" -f $ip, $(if ($t.TcpTestSucceeded) { 'erişilebilir' } else { 'ERİŞİLEMİYOR' })) `
                $(if ($t.TcpTestSucceeded) { 'Iyi' } else { 'Hata' })
        }
    } else {
        Yaz 'İletici tanımlı değil; kök ipuçları kullanılıyor. Kurumsal ağlarda genelde iletici istenir.' Uyari
    }

    # ------------------------------------------------------------ scavenging
    Yaz "`n--- 4. Kayıt temizleme (scavenging) ---" Baslik
    $sc = Get-DnsServerScavenging -ComputerName $Sunucu
    Yaz "Sunucu genelinde: $($sc.ScavengingState)" $(if ($sc.ScavengingState) { 'Iyi' } else { 'Uyari' })
    if (-not $sc.ScavengingState) {
        Yaz 'Kapalı: eski kayıtlar birikir ve zamanla yanlış IP''ye çözümleme başlar.' Uyari
        Yaz 'Açmadan önce yenileme aralıklarını planlayın; aceleyle açmak canlı kayıtları silebilir.' Bilgi
    }
}

# ------------------------------------------------------- 5. AD kayıtları
Yaz "`n--- 5. Etki alanı kayıtları ---" Baslik
$srvKayitlari = @(
    "_ldap._tcp.dc._msdcs.$Alan",
    "_kerberos._tcp.dc._msdcs.$Alan",
    "_ldap._tcp.$Alan"
)
foreach ($k in $srvKayitlari) {
    $sonuc = Resolve-DnsName $k -Type SRV -Server $Sunucu -ErrorAction SilentlyContinue
    if ($sonuc) {
        $hedefler = ($sonuc | Where-Object NameTarget | Select-Object -ExpandProperty NameTarget) -join ', '
        Yaz "  $k → $hedefler" Iyi
    } else {
        Yaz "  $k → KAYIT YOK" Hata
        Yaz '    Bu kayıt olmadan istemciler denetleyici bulamaz; oturum açma ve ilke işlemez.' Uyari
    }
}

# --------------------------------------------------------- 6. çözümleme
Yaz "`n--- 6. Çözümleme sınamaları ---" Baslik
foreach ($ad in $Alan, "www.microsoft.com", $env:COMPUTERNAME) {
    $r = Resolve-DnsName $ad -Server $Sunucu -ErrorAction SilentlyContinue | Select-Object -First 1
    Yaz ("  {0,-28} → {1}" -f $ad, $(if ($r) { $(if ($r.IPAddress) { $r.IPAddress } else { $r.NameHost }) } else { 'ÇÖZÜLEMEDİ' })) `
        $(if ($r) { 'Iyi' } else { 'Hata' })
}

Yaz "`n--- Özet ---" Baslik
Yaz 'İstemcide dış DNS         → AD kayıtları çözülemez, belirti "bazen çalışıyor" olur'
Yaz 'SRV kaydı yok             → oturum açma ve grup ilkesi çalışmaz'
Yaz 'Dinamik güncelleme güvensiz → kimliksiz makineler kayıt yazabilir'
Yaz 'Scavenging kapalı         → eski kayıtlar yanlış IP''ye götürür'
Yaz 'İletici erişilemiyor      → dış çözümleme durur, iç çalışmaya devam eder'
