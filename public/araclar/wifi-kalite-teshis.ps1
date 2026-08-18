<#
.SYNOPSIS
    "Wi-Fi bağlı ama sürekli kopuyor" durumunda sinyal, kanal, sürücü ve
    kopma geçmişini tek raporda toplar.

.DESCRIPTION
    Kopmanın dört tipik sebebini ayırt eder: zayıf sinyal, kalabalık kanal,
    güç yönetiminin kartı uyutması ve sürücü/roaming davranışı. Ayrıca
    WLAN-AutoConfig olay günlüğünden son kopmaları çıkarır — kullanıcının
    "sabahları oluyor" cümlesi böyle doğrulanır.

    Yalnızca -GucAyari verildiğinde değişiklik yapar (kartın güç tasarrufunu
    kapatır); onun dışında rapor üretir.

.PARAMETER Sure
    Sinyal örneklemesinin saniye cinsinden süresi. Varsayılan 20.

.PARAMETER GucAyari
    Ağ kartının güç tasarrufu ayarını kapatır (yönetici hakkı ister).

.EXAMPLE
    .\wifi-kalite-teshis.ps1
    .\wifi-kalite-teshis.ps1 -Sure 60

.NOTES
    bilgince.com — Hızlı Çözümler
#>

[CmdletBinding()]
param(
    [int]$Sure = 20,
    [switch]$GucAyari
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

Yaz "=== Wi-Fi kalite teşhisi — $(Get-Date -f 'dd.MM.yyyy HH:mm') ===" Baslik

# ------------------------------------------------------------- 1. bağlantı
Yaz "`n--- 1. Bağlantı ---" Baslik
$arayuz = netsh wlan show interfaces
if (-not ($arayuz | Select-String 'SSID')) {
    Yaz 'Bağlı bir kablosuz ağ yok ya da WLAN hizmeti çalışmıyor.' Hata
    return
}
$arayuz | Select-String 'SSID|BSSID|Sinyal|Signal|Radyo|Radio|Kanal|Channel|Alma|Receive|İletim|Transmit|Kimlik|Authentication' |
    ForEach-Object { Yaz "  $($_.ToString().Trim())" }

$sinyalSatir = ($arayuz | Select-String 'Sinyal|Signal') -replace '[^\d]', ''
$sinyal = if ($sinyalSatir) { [int]$sinyalSatir } else { 0 }

if ($sinyal -ge 70) { Yaz "Sinyal %$sinyal — iyi" Iyi }
elseif ($sinyal -ge 50) { Yaz "Sinyal %$sinyal — sınırda; kopmaların sebebi bu olabilir" Uyari }
else { Yaz "Sinyal %$sinyal — zayıf. Önce mesafe/engel sorununu çözün" Hata }

# --------------------------------------------------------------- 2. örnekleme
Yaz "`n--- 2. $Sure saniyelik sinyal örneklemesi ---" Baslik
$olcumler = @()
for ($i = 0; $i -lt $Sure; $i += 2) {
    $s = (netsh wlan show interfaces | Select-String 'Sinyal|Signal') -replace '[^\d]', ''
    if ($s) { $olcumler += [int]$s }
    Start-Sleep -Seconds 2
}
if ($olcumler.Count -gt 1) {
    $ist = $olcumler | Measure-Object -Minimum -Maximum -Average
    Yaz ("En düşük %{0} · En yüksek %{1} · Ortalama %{2}" -f
        $ist.Minimum, $ist.Maximum, [math]::Round($ist.Average))
    $oynama = $ist.Maximum - $ist.Minimum
    if ($oynama -gt 25) {
        Yaz "Sinyal $oynama puan oynuyor — cihaz baz istasyonları arasında gidip geliyor olabilir (roaming)." Uyari
    }
}

# ----------------------------------------------------------------- 3. kanal
Yaz "`n--- 3. Ortamdaki ağlar ve kanal kalabalığı ---" Baslik
$aglar = netsh wlan show networks mode=bssid
$kanallar = $aglar | Select-String 'Kanal|Channel' | ForEach-Object { ($_ -replace '[^\d]', '') } | Where-Object { $_ }
if ($kanallar) {
    $kanallar | Group-Object | Sort-Object Count -Descending |
        Select-Object @{n='Kanal';e={$_.Name}}, @{n='AgSayisi';e={$_.Count}} -First 10 | Format-Table -AutoSize
    Yaz '2.4 GHz bandında yalnızca 1, 6 ve 11 çakışmaz. Aynı kanalda 3+ ağ varsa kanal değiştirin.' Bilgi
} else {
    Yaz 'Ortam taraması boş döndü (bazı sürücüler yönetici hakkı ister).' Bilgi
}

# ---------------------------------------------------------------- 4. sürücü
Yaz "`n--- 4. Sürücü ve güç yönetimi ---" Baslik
$kart = Get-NetAdapter -Physical | Where-Object { $_.InterfaceDescription -match 'Wi-?Fi|Wireless|802\.11|WLAN' } | Select-Object -First 1
if ($kart) {
    Get-NetAdapter -Name $kart.Name | Select-Object Name, InterfaceDescription, DriverVersion, DriverDate, LinkSpeed | Format-List

    $guc = Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable |
        Where-Object InstanceName -match ($kart.PnPDeviceID -replace '\\', '\\\\')
    if ($guc -and $guc.Enable) {
        Yaz 'Güç tasarrufu AÇIK: Windows kartı uyutabilir, uyandığında bağlantı kopmuş görünür.' Uyari
        Yaz 'Kapatmak için: .\wifi-kalite-teshis.ps1 -GucAyari' Bilgi
    } elseif ($guc) {
        Yaz 'Güç tasarrufu kapalı.' Iyi
    }

    if ($kart.DriverDate -and ([datetime]$kart.DriverDate) -lt (Get-Date).AddYears(-3)) {
        Yaz "Sürücü tarihi $((([datetime]$kart.DriverDate)).ToString('yyyy-MM')) — üç yıldan eski. Üretici sitesinden güncelleyin." Uyari
    }
}

# ------------------------------------------------------------- 5. kopma geçmişi
Yaz "`n--- 5. Son kopmalar (son 3 gün) ---" Baslik
$olaylar = Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-WLAN-AutoConfig/Operational'
    Id        = 8003, 8002, 11004, 11005, 12013
    StartTime = (Get-Date).AddDays(-3)
} -MaxEvents 60

if ($olaylar) {
    $olaylar | Group-Object Id | ForEach-Object {
        $ad = @{ 8003 = 'Bağlantı koptu'; 8002 = 'Bağlanma başarısız'; 11004 = 'Kimlik doğrulama başarısız'; 11005 = 'Kimlik doğrulama tamam'; 12013 = 'Ağ değişti' }[[int]$_.Name]
        Yaz ("  {0,-28} {1} kez" -f $ad, $_.Count)
    }
    Yaz "`nSon beş olay:"
    $olaylar | Select-Object -First 5 TimeCreated, Id, @{n='Mesaj';e={($_.Message -split "`n")[0]}} | Format-Table -AutoSize

    $saatler = $olaylar | Group-Object { $_.TimeCreated.Hour } | Sort-Object Count -Descending | Select-Object -First 3
    Yaz 'Kopmaların yoğunlaştığı saatler:'
    $saatler | ForEach-Object { Yaz ("  {0}:00 civarı — {1} olay" -f $_.Name, $_.Count) }
    Yaz 'Belirli bir saatte yoğunlaşıyorsa sebep genelde ortam değil, zamanlanmış bir iş ya da vardiya yoğunluğudur.' Bilgi
} else {
    Yaz 'Son üç günde kopma olayı yok — sorun kablosuz katmanda olmayabilir.' Iyi
}

# ------------------------------------------------------------- güç ayarı
if ($GucAyari -and $kart) {
    Yaz "`n--- Güç tasarrufu kapatılıyor ---" Baslik
    try {
        Disable-NetAdapterPowerManagement -Name $kart.Name -Confirm:$false
        Yaz 'Kapatıldı. Kart kısa süre için yeniden başlatılmış olabilir.' Iyi
    } catch {
        Yaz "Değiştirilemedi: $($_.Exception.Message)" Hata
    }
}

Yaz "`n--- Özet ---" Baslik
Yaz 'Sinyal < %50            → konum/kapsama sorunu, ayar değil'
Yaz 'Sinyal oynak            → roaming; erişim noktası güçleri fazla yüksek olabilir'
Yaz 'Aynı kanalda çok ağ     → kanal planı'
Yaz 'Güç tasarrufu açık      → dizüstülerde en sık görülen kopma sebebi'
Yaz 'Kimlik doğrulama hatası → 802.1X/sertifika tarafı, kablosuz tarafı değil'
