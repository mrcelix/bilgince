<#
.SYNOPSIS
    "Sunucu yavaş" şikâyetinde darboğazın işlemci mi, bellek mi, disk mi yoksa
    ağ mı olduğunu ölçerek ayırır.

.DESCRIPTION
    Tahminle değil sayaçla çalışır. Belirli bir süre örnekleme yapar ve dört
    katmanı ayrı ayrı puanlar: işlemci kuyruğu, bellek baskısı ve sayfalama,
    disk gecikmesi ve kuyruk uzunluğu, ağ hataları. Sonunda en olası darboğazı
    ve o katmanda bakılacak sonraki şeyi söyler.

    Değişiklik yapmaz.

.PARAMETER Saniye
    Örnekleme süresi. Varsayılan 30.

.PARAMETER EnCok
    Kaynak tüketiminde listelenecek süreç sayısı. Varsayılan 8.

.EXAMPLE
    .\yavas-sunucu-teshis.ps1
    .\yavas-sunucu-teshis.ps1 -Saniye 120

.NOTES
    bilgince.com — Hızlı Çözümler
    Şikâyet sürerken çalıştırın; sorun geçtikten sonraki ölçüm bir şey söylemez.
#>

[CmdletBinding()]
param(
    [int]$Saniye = 30,
    [int]$EnCok = 8
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

$bulgular = @()
function Bulgu { param([string]$Katman, [string]$Metin, [int]$Puan) $script:bulgular += [pscustomobject]@{ Katman = $Katman; Metin = $Metin; Puan = $Puan } }

Yaz "=== Yavaşlık teşhisi — $env:COMPUTERNAME — $Saniye saniye örnekleme ===" Baslik

$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$cekirdek = $cs.NumberOfLogicalProcessors
$ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
Yaz "$cekirdek mantıksal çekirdek · $ramGB GB bellek · $($os.Caption)"
Yaz "Çalışma süresi: $([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)) gün"

# ------------------------------------------------------------- örnekleme
Yaz "`nSayaçlar toplanıyor…" Bilgi
$sayaclar = @(
    '\Processor(_Total)\% Processor Time',
    '\System\Processor Queue Length',
    '\Memory\Available MBytes',
    '\Memory\Pages/sec',
    '\PhysicalDisk(_Total)\Avg. Disk sec/Read',
    '\PhysicalDisk(_Total)\Avg. Disk sec/Write',
    '\PhysicalDisk(_Total)\Current Disk Queue Length'
)
$ornek = Get-Counter -Counter $sayaclar -SampleInterval 2 -MaxSamples ([math]::Max(2, [int]($Saniye / 2)))

function Ortalama([string]$Desen) {
    ($ornek.CounterSamples | Where-Object Path -like "*$Desen*" | Measure-Object CookedValue -Average).Average
}

# ------------------------------------------------------------------ CPU
Yaz "`n--- 1. İşlemci ---" Baslik
$cpu = Ortalama 'processor time'
$kuyruk = Ortalama 'processor queue length'
Yaz ("Ortalama kullanım: %{0:N1}   Kuyruk: {1:N1}" -f $cpu, $kuyruk)

if ($cpu -gt 85) { Bulgu 'İşlemci' "Kullanım %$([math]::Round($cpu)) — doygun" 3 }
elseif ($cpu -gt 70) { Bulgu 'İşlemci' "Kullanım %$([math]::Round($cpu)) — yüksek" 2 }
if ($kuyruk -gt ($cekirdek * 2)) {
    Bulgu 'İşlemci' "Kuyruk uzunluğu $([math]::Round($kuyruk,1)) — çekirdek başına 2'nin üstünde, iş bekliyor" 3
}

Get-Process | Sort-Object CPU -Descending | Select-Object -First $EnCok Name, Id,
    @{n='CPU_sn';e={[math]::Round($_.CPU)}}, @{n='Bellek_MB';e={[math]::Round($_.WorkingSet64/1MB)}} |
    Format-Table -AutoSize

# ---------------------------------------------------------------- bellek
Yaz "--- 2. Bellek ---" Baslik
$bosMB = Ortalama 'available mbytes'
$sayfa = Ortalama 'pages/sec'
$kullanimYuzde = 100 - ($bosMB / ($ramGB * 1024) * 100)
Yaz ("Boş: {0:N0} MB   Kullanım: %{1:N0}   Sayfalama: {2:N0}/sn" -f $bosMB, $kullanimYuzde, $sayfa)

if ($bosMB -lt 512) { Bulgu 'Bellek' "Yalnızca $([math]::Round($bosMB)) MB boş — sistem sayfalamaya zorlanıyor" 3 }
elseif ($kullanimYuzde -gt 90) { Bulgu 'Bellek' "Kullanım %$([math]::Round($kullanimYuzde))" 2 }
if ($sayfa -gt 1000) { Bulgu 'Bellek' "Sayfalama $([math]::Round($sayfa))/sn — bellek yetmiyor, disk yükleniyor" 3 }

Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First $EnCok Name, Id,
    @{n='Bellek_MB';e={[math]::Round($_.WorkingSet64/1MB)}} | Format-Table -AutoSize

# ------------------------------------------------------------------ disk
Yaz "--- 3. Disk ---" Baslik
$okuma = (Ortalama 'disk sec/read') * 1000
$yazma = (Ortalama 'disk sec/write') * 1000
$diskKuyruk = Ortalama 'current disk queue length'
Yaz ("Okuma gecikmesi: {0:N1} ms   Yazma: {1:N1} ms   Kuyruk: {2:N1}" -f $okuma, $yazma, $diskKuyruk)

if ($okuma -gt 25 -or $yazma -gt 25) {
    Bulgu 'Disk' "Gecikme okuma $([math]::Round($okuma))ms / yazma $([math]::Round($yazma))ms — 25 ms üstü kullanıcıya yavaşlık olarak yansır" 3
} elseif ($okuma -gt 15 -or $yazma -gt 15) {
    Bulgu 'Disk' "Gecikme sınırda (okuma $([math]::Round($okuma))ms)" 2
}
if ($diskKuyruk -gt 4) { Bulgu 'Disk' "Disk kuyruğu $([math]::Round($diskKuyruk,1)) — istekler sıraya giriyor" 2 }

Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used } |
    Select-Object Name, @{n='Bos_GB';e={[math]::Round($_.Free/1GB,1)}},
        @{n='Doluluk';e={"%$([math]::Round($_.Used/($_.Used+$_.Free)*100))"}} | Format-Table -AutoSize

foreach ($s in Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -and ($_.Free / ($_.Used + $_.Free)) -lt 0.1 }) {
    Bulgu 'Disk' "$($s.Name): sürücüsünde %10'dan az boş alan kaldı" 2
}

# -------------------------------------------------------------------- ağ
Yaz "--- 4. Ağ ---" Baslik
Get-NetAdapterStatistics | Where-Object { $_.ReceivedBytes -gt 0 } |
    Select-Object Name, @{n='Alinan_GB';e={[math]::Round($_.ReceivedBytes/1GB,2)}},
        @{n='Gonderilen_GB';e={[math]::Round($_.SentBytes/1GB,2)}},
        @{n='Hata';e={$_.ReceivedPacketErrors + $_.OutboundPacketErrors}} | Format-Table -AutoSize

$hatali = Get-NetAdapterStatistics | Where-Object { ($_.ReceivedPacketErrors + $_.OutboundPacketErrors) -gt 100 }
if ($hatali) { Bulgu 'Ağ' "Ağ kartında paket hatası var: $($hatali.Name -join ', ')" 2 }

# --------------------------------------------------------- 5. son olaylar
Yaz "--- 5. Son 24 saatte kritik olaylar ---" Baslik
$olaylar = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = (Get-Date).AddDays(-1) } -MaxEvents 100
if ($olaylar) {
    $olaylar | Group-Object Id | Sort-Object Count -Descending | Select-Object -First 6 Count, Name | Format-Table -AutoSize
    if ($olaylar | Where-Object Id -in 51, 129, 153) { Bulgu 'Disk' 'Olay günlüğünde disk G/Ç hataları var (51/129/153)' 3 }
    if ($olaylar | Where-Object Id -eq 2019) { Bulgu 'Bellek' 'Sayfalanmayan havuz tükenmiş (olay 2019) — sürücü sızıntısı' 3 }
} else {
    Yaz 'Kritik olay yok.' Iyi
}

# ------------------------------------------------------------------ sonuç
Yaz "`n=== Sonuç ===" Baslik
if (-not $bulgular) {
    Yaz 'Ölçüm süresince darboğaz görünmedi.' Iyi
    Yaz 'Şikâyet sürüyorsa: ölçümü sorun yaşanırken tekrarlayın ya da yavaşlık uygulama katmanındadır.' Bilgi
} else {
    $sirali = $bulgular | Group-Object Katman | Sort-Object { ($_.Group | Measure-Object Puan -Sum).Sum } -Descending
    Yaz "En olası darboğaz: $($sirali[0].Name)" Hata
    foreach ($g in $sirali) {
        Yaz "`n[$($g.Name)]" Baslik
        $g.Group | ForEach-Object { Yaz "  • $($_.Metin)" $(if ($_.Puan -ge 3) { 'Hata' } else { 'Uyari' }) }
    }
    Yaz "`nSonraki adım:" Bilgi
    Yaz '  İşlemci → en çok tüketen sürecin ne yaptığına bakın; sanal makinede vCPU aşırı taahhüdü olabilir'
    Yaz '  Bellek  → sayfalama varsa RAM ekleyin; havuz sızıntısında poolmon ile etiketi bulun'
    Yaz '  Disk    → depolama katmanı (SAN yolu, RAID yeniden yapılandırma, komşu gürültüsü)'
    Yaz '  Ağ      → kablo/port hataları, çift yönlü uyuşmazlık, sürücü'
}
