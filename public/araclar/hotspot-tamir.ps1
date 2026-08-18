<#
.SYNOPSIS
    Kafe, otel ve havaalanı hotspot'larında "bağlandı ama internet yok"
    durumunu çözmeye çalışır.

.DESCRIPTION
    Karşılama sayfası (captive portal) açılmayan bağlantılarda en sık görülen
    beş sebebi sırayla ele alır:

      1. Sabit DNS sunucusu tanımlı olması (en yaygın sebep). Karşılama sayfası
         DNS yönlendirmesiyle çalışır; 8.8.8.8 gibi sabit bir sunucu tanımlıysa
         portal hiç açılmaz.
      2. Eski DNS önbelleği
      3. Bayat DHCP kirası
      4. Kurumsal ağdan kalan vekil (proxy) ayarları
      5. Kapalı kalmış bağlantı algılama

    Değişiklikleri geri almak için: .\hotspot-tamir.ps1 -GeriAl

.PARAMETER Arayuz
    İşlem yapılacak ağ arayüzü. Verilmezse etkin kablosuz arayüz seçilir.

.PARAMETER GeriAl
    Betiğin kaydettiği önceki DNS ve vekil ayarlarını geri yükler.

.PARAMETER Rapor
    Hiçbir değişiklik yapmaz; yalnızca mevcut durumu raporlar.

.EXAMPLE
    .\hotspot-tamir.ps1
    Etkin kablosuz arayüzde onarım adımlarını çalıştırır.

.EXAMPLE
    .\hotspot-tamir.ps1 -Rapor
    Sorunun nerede olduğunu gösterir, hiçbir şey değiştirmez.

.EXAMPLE
    .\hotspot-tamir.ps1 -GeriAl
    Kurumsal ağa döndüğünüzde önceki ayarları geri yükler.

.NOTES
    bilgince.com — Hızlı Çözümler
    Yönetici olarak çalıştırılmalıdır (DNS ve DHCP işlemleri için).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Arayuz,
    [switch]$GeriAl,
    [switch]$Rapor
)

$ErrorActionPreference = 'Stop'
$YedekDosyasi = Join-Path $env:LOCALAPPDATA 'bilgince-hotspot-yedek.json'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red' }[$Tur]
    $isaret = @{ Bilgi = '  '; Iyi = 'OK'; Uyari = '!!'; Hata = 'XX' }[$Tur]
    Write-Host ("{0} {1}" -f $isaret, $Metin) -ForegroundColor $renk
}

function Get-HedefArayuz {
    if ($Arayuz) {
        return Get-NetAdapter -Name $Arayuz
    }
    $a = Get-NetAdapter -Physical |
        Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Virtual|Loopback' } |
        Sort-Object -Property @{ E = { $_.InterfaceDescription -match 'Wi-?Fi|Wireless|802\.11' } } -Descending |
        Select-Object -First 1
    if (-not $a) { throw 'Etkin bir ağ arayüzü bulunamadı.' }
    return $a
}

function Test-Portal {
    # Karşılama sayfası varsa bu adres 200 yerine yönlendirme döner.
    try {
        $y = Invoke-WebRequest -Uri 'http://www.msftconnecttest.com/connecttest.txt' `
            -UseBasicParsing -TimeoutSec 6 -MaximumRedirection 0 -ErrorAction Stop
        if ($y.Content.Trim() -eq 'Microsoft Connect Test') {
            return [pscustomobject]@{ Durum = 'Internet'; Adres = $null }
        }
        return [pscustomobject]@{ Durum = 'Portal'; Adres = $null }
    } catch {
        $yanit = $_.Exception.Response
        if ($yanit -and [int]$yanit.StatusCode -in 301, 302, 303, 307) {
            return [pscustomobject]@{ Durum = 'Portal'; Adres = $yanit.Headers.Location }
        }
        return [pscustomobject]@{ Durum = 'Yok'; Adres = $null }
    }
}

# ---------------------------------------------------------------- geri alma
if ($GeriAl) {
    if (-not (Test-Path $YedekDosyasi)) { Yaz 'Yedek bulunamadı, geri alınacak bir şey yok.' Uyari; return }
    $yedek = Get-Content $YedekDosyasi -Raw | ConvertFrom-Json

    if ($yedek.DnsSunuculari -and $yedek.DnsSunuculari.Count -gt 0) {
        Set-DnsClientServerAddress -InterfaceIndex $yedek.ArayuzIndex -ServerAddresses $yedek.DnsSunuculari
        Yaz "DNS geri yüklendi: $($yedek.DnsSunuculari -join ', ')" Iyi
    }
    if ($yedek.VekilAcik) {
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 1
        Yaz 'Vekil ayarı geri açıldı.' Iyi
    }
    Remove-Item $YedekDosyasi -Force
    Yaz 'Geri alma tamamlandı.' Iyi
    return
}

# ------------------------------------------------------------------- durum
$adapter = Get-HedefArayuz
Yaz "Arayüz: $($adapter.Name) — $($adapter.InterfaceDescription)"

$dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
$sabitDns = @($dns.ServerAddresses)
$ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '169.254.*' }
$vekil = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue

Yaz ("IP adresi   : {0}" -f ($(if ($ip) { $ip.IPAddress } else { 'YOK (169.254.x = DHCP alınamadı)' })))
Yaz ("DNS         : {0}" -f ($(if ($sabitDns) { $sabitDns -join ', ' } else { 'DHCP (doğru)' })))
Yaz ("Vekil       : {0}" -f ($(if ($vekil.ProxyEnable -eq 1) { "AÇIK — $($vekil.ProxyServer)" } else { 'kapalı (doğru)' })))

$portal = Test-Portal
switch ($portal.Durum) {
    'Internet' { Yaz 'İnternet erişimi zaten çalışıyor.' Iyi }
    'Portal'   { Yaz 'Karşılama sayfası algılandı — giriş yapmanız gerekiyor.' Uyari }
    'Yok'      { Yaz 'Ağa erişim yok; DNS veya DHCP sorunu olabilir.' Hata }
}

if ($Rapor) { Yaz 'Rapor modu: hiçbir değişiklik yapılmadı.' Bilgi; return }
if ($portal.Durum -eq 'Internet') { return }

# ------------------------------------------------------------------ onarım
$yedek = [ordered]@{
    ArayuzIndex   = $adapter.ifIndex
    ArayuzAdi     = $adapter.Name
    DnsSunuculari = $sabitDns
    VekilAcik     = ($vekil.ProxyEnable -eq 1)
    Zaman         = (Get-Date).ToString('o')
}
$yedek | ConvertTo-Json | Set-Content $YedekDosyasi -Encoding utf8

# 1. Sabit DNS'i kaldır — karşılama sayfalarının en yaygın engeli
if ($sabitDns.Count -gt 0) {
    if ($PSCmdlet.ShouldProcess($adapter.Name, 'DNS ayarını DHCP''ye çevir')) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
        Yaz 'Sabit DNS kaldırıldı, DHCP''den alınacak.' Iyi
    }
} else {
    Yaz 'DNS zaten DHCP''den geliyor.' Bilgi
}

# 2. Vekil ayarını kapat
if ($vekil.ProxyEnable -eq 1) {
    if ($PSCmdlet.ShouldProcess('Internet Settings', 'Vekil ayarını kapat')) {
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 0
        Yaz 'Vekil ayarı kapatıldı.' Iyi
    }
}

# 3. DNS önbelleğini temizle
Clear-DnsClientCache
Yaz 'DNS önbelleği temizlendi.' Iyi

# 4. DHCP kirasını yenile
if ($PSCmdlet.ShouldProcess($adapter.Name, 'DHCP kirasını yenile')) {
    & ipconfig /release  "$($adapter.Name)" | Out-Null
    & ipconfig /renew    "$($adapter.Name)" | Out-Null
    Start-Sleep -Seconds 3
    Yaz 'DHCP kirası yenilendi.' Iyi
}

# 5. Sonucu değerlendir ve gerekirse portalı aç
$portal = Test-Portal
switch ($portal.Durum) {
    'Internet' {
        Yaz 'İnternet erişimi sağlandı.' Iyi
    }
    'Portal' {
        Yaz 'Karşılama sayfası açılıyor…' Uyari
        Start-Process ($(if ($portal.Adres) { $portal.Adres } else { 'http://neverssl.com' }))
        Yaz 'Tarayıcıda giriş yaptıktan sonra bu betiği -Rapor ile tekrar çalıştırıp doğrulayın.' Bilgi
    }
    'Yok' {
        Yaz 'Hâlâ erişim yok. Kablosuz ağdan çıkıp yeniden bağlanmayı deneyin.' Hata
        Yaz 'Sorun sürerse yönetici olarak: netsh winsock reset (ardından yeniden başlatma gerekir).' Bilgi
    }
}

Yaz "Kurumsal ağa döndüğünüzde ayarları geri almak için: .\hotspot-tamir.ps1 -GeriAl" Bilgi
