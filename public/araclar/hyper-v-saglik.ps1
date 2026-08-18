<#
.SYNOPSIS
    Hyper-V ana makinesinin ve üzerindeki sanal makinelerin sağlığını çıkarır.

.DESCRIPTION
    Sanallaştırmada sorunların çoğu ana makinede birikir ve sanal makinede
    görünür. Bu betik ikisini birlikte raporlar: kaynak aşırı taahhüdü, yaşlanmış
    denetim noktaları, dinamik bellek baskısı, tümleştirme hizmeti sürümleri,
    replikasyon sağlığı, sanal disk türleri ve depolama gecikmesi.

    Değişiklik yapmaz.

.PARAMETER Gun
    Denetim noktası yaş uyarısı için eşik. Varsayılan 7.

.EXAMPLE
    .\hyper-v-saglik.ps1
    .\hyper-v-saglik.ps1 -Gun 3

.NOTES
    bilgince.com — Hızlı Çözümler
    Hyper-V ana makinesinde, yönetici olarak çalıştırın.
#>

[CmdletBinding()]
param([int]$Gun = 7)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

if (-not (Get-Command Get-VM -ErrorAction SilentlyContinue)) {
    Yaz 'Hyper-V yönetim araçları bulunamadı. Bu betik ana makinede çalıştırılmalı.' Hata
    return
}

Yaz "=== Hyper-V sağlık raporu — $env:COMPUTERNAME — $(Get-Date -f 'dd.MM.yyyy HH:mm') ===" Baslik

# --------------------------------------------------------- 1. ana makine
Yaz "`n--- 1. Ana makine kaynakları ---" Baslik
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$anaRamGB = [math]::Round($cs.TotalPhysicalMemory / 1GB)
$bosRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$cekirdek = $cs.NumberOfLogicalProcessors

$vmler = Get-VM
$calisan = $vmler | Where-Object State -eq 'Running'

$atananVCPU = ($calisan | Measure-Object ProcessorCount -Sum).Sum
$atananRamGB = [math]::Round((($calisan | Measure-Object MemoryAssigned -Sum).Sum) / 1GB, 1)

Yaz "Fiziksel: $cekirdek mantıksal çekirdek · $anaRamGB GB bellek (boş $bosRamGB GB)"
Yaz "Çalışan sanal makine: $($calisan.Count) / $($vmler.Count)"
Yaz "Atanan: $atananVCPU vCPU · $atananRamGB GB bellek"

$oran = if ($cekirdek) { [math]::Round($atananVCPU / $cekirdek, 2) } else { 0 }
Yaz "vCPU aşırı taahhüt oranı: $oran : 1" $(if ($oran -le 2) { 'Iyi' } elseif ($oran -le 4) { 'Uyari' } else { 'Hata' })
if ($oran -gt 4) { Yaz '  4:1 üstü oran, yoğun anlarda belirgin gecikme üretir.' Uyari }
if ($bosRamGB -lt 4) { Yaz "  Ana makinede yalnızca $bosRamGB GB boş bellek — yeni makine başlatılamayabilir." Hata }

# ------------------------------------------------------ 2. sanal makineler
Yaz "`n--- 2. Sanal makineler ---" Baslik
$vmler | Sort-Object State, Name |
    Select-Object Name, State, ProcessorCount,
        @{n='Bellek_GB';e={[math]::Round($_.MemoryAssigned/1GB,1)}},
        @{n='Dinamik';e={$_.DynamicMemoryEnabled}},
        @{n='Calisma';e={ if ($_.Uptime) { "$([math]::Round($_.Uptime.TotalDays))g" } else { '-' } }},
        Version | Format-Table -AutoSize

# Dinamik bellek baskısı: %80 üstü, konuk bellek istiyor ama alamıyor demektir
foreach ($vm in $calisan | Where-Object DynamicMemoryEnabled) {
    $baski = (Get-VM $vm.Name).MemoryDemand / $vm.MemoryAssigned * 100
    if ($baski -gt 90) {
        Yaz "$($vm.Name): bellek baskısı %$([math]::Round($baski)) — konuk daha fazla bellek istiyor" Hata
    } elseif ($baski -gt 80) {
        Yaz "$($vm.Name): bellek baskısı %$([math]::Round($baski))" Uyari
    }
}

# Eski yapılandırma sürümü: yeni özellikleri kullanamaz
$eski = $vmler | Where-Object { [version]$_.Version -lt [version]'9.0' }
if ($eski) {
    Yaz "`nEski yapılandırma sürümlü makineler: $($eski.Name -join ', ')" Uyari
    Yaz 'Update-VMVersion ile yükseltilebilir; geri dönüşü yoktur, önce yedek alın.' Bilgi
}

# ------------------------------------------------- 3. denetim noktaları
Yaz "`n--- 3. Denetim noktaları ---" Baslik
$noktalar = $vmler | Get-VMSnapshot
if ($noktalar) {
    $noktalar | Select-Object VMName, Name, SnapshotType, CreationTime,
        @{n='Yas_gun';e={[math]::Round(((Get-Date) - $_.CreationTime).TotalDays)}} |
        Sort-Object Yas_gun -Descending | Format-Table -AutoSize

    $yasli = $noktalar | Where-Object { ((Get-Date) - $_.CreationTime).TotalDays -gt $Gun }
    if ($yasli) {
        Yaz "$($yasli.Count) denetim noktası $Gun günden eski." Hata
        Yaz 'Denetim noktası yedek değildir: fark diski büyüdükçe disk dolar ve performans düşer.' Uyari
        Yaz 'Birleştirme (merge) işlemi de zaman ve disk alanı ister; ne kadar beklerseniz o kadar pahalı.' Bilgi
    } else {
        Yaz "Tüm denetim noktaları $Gun günden yeni." Iyi
    }
} else {
    Yaz 'Denetim noktası yok.' Iyi
}

# ------------------------------------------------------ 4. sanal diskler
Yaz "`n--- 4. Sanal diskler ---" Baslik
foreach ($vm in $vmler) {
    foreach ($sd in Get-VMHardDiskDrive -VM $vm) {
        $bilgi = Get-VHD $sd.Path -ErrorAction SilentlyContinue
        if (-not $bilgi) { continue }
        $satir = "{0,-22} {1,-10} {2,7:N1} GB / {3,7:N1} GB  {4}" -f $vm.Name, $bilgi.VhdType,
            ($bilgi.FileSize / 1GB), ($bilgi.Size / 1GB), (Split-Path $sd.Path -Leaf)
        $tur = if ($bilgi.VhdType -eq 'Differencing') { 'Uyari' } else { 'Bilgi' }
        Yaz "  $satir" $tur
    }
}
Yaz 'Differencing (fark) disk gören satır varsa açık bir denetim noktası ya da bağlantılı klon vardır.' Bilgi

# --------------------------------------------------------- 5. replikasyon
Yaz "`n--- 5. Replikasyon ---" Baslik
$rep = Get-VMReplication
if ($rep) {
    $rep | Select-Object VMName, State, Health, Mode, LastReplicationTime | Format-Table -AutoSize
    foreach ($r in $rep | Where-Object { $_.Health -ne 'Normal' -or ((Get-Date) - $_.LastReplicationTime).TotalHours -gt 2 }) {
        Yaz "$($r.VMName): sağlık $($r.Health), son kopya $($r.LastReplicationTime)" Hata
    }
} else {
    Yaz 'Replikasyon yapılandırılmamış.' Bilgi
}

# ------------------------------------------------------ 6. depolama gecikmesi
Yaz "`n--- 6. Depolama gecikmesi (10 sn örnekleme) ---" Baslik
$sayac = Get-Counter '\PhysicalDisk(_Total)\Avg. Disk sec/Transfer' -SampleInterval 2 -MaxSamples 5
$ms = ($sayac.CounterSamples | Measure-Object CookedValue -Average).Average * 1000
Yaz ("Ortalama aktarım gecikmesi: {0:N1} ms" -f $ms) $(if ($ms -lt 15) { 'Iyi' } elseif ($ms -lt 25) { 'Uyari' } else { 'Hata' })
if ($ms -ge 25) { Yaz '25 ms üstü gecikme, tüm sanal makinelerde yavaşlık olarak görünür.' Uyari }

# ----------------------------------------------------------- 7. olaylar
Yaz "`n--- 7. Son 3 günde Hyper-V olayları ---" Baslik
$olaylar = Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-Hyper-V-VMMS-Admin', 'Microsoft-Windows-Hyper-V-Worker-Admin'
    Level     = 1, 2, 3
    StartTime = (Get-Date).AddDays(-3)
} -MaxEvents 30
if ($olaylar) {
    $olaylar | Select-Object -First 8 TimeCreated, Id, @{n='Mesaj';e={($_.Message -split "`n")[0]}} | Format-Table -AutoSize
} else {
    Yaz 'Uyarı ya da hata yok.' Iyi
}

Yaz "`n--- Özet ---" Baslik
Yaz 'vCPU oranı 4:1 üstü        → yoğun anlarda gecikme'
Yaz 'Bellek baskısı %90 üstü    → konuk bellek istiyor, ana makinede yok'
Yaz 'Eski denetim noktası       → disk dolar, performans düşer; birleştirin'
Yaz 'Fark diski                 → açık denetim noktası ya da klon'
Yaz 'Depolama gecikmesi 25 ms+  → darboğaz sanal makinede değil, depolamada'
