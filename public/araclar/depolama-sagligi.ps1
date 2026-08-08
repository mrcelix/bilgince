<#
.SYNOPSIS
    Disklerin fiziksel sağlığını, birim durumunu ve yaklaşan arıza işaretlerini
    raporlar.

.DESCRIPTION
    Disk arızası çoğu zaman sessiz başlar: önce yeniden denenen okumalar, sonra
    yavaşlık, en sonda kayıp. Bu betik erken işaretleri toplar: fiziksel disk
    sağlık durumu, güvenilirlik sayaçları (SMART karşılığı), depolama havuzu ve
    sanal disk durumu, birim sağlığı, doluluk ve disk hatası olayları.

    Değişiklik yapmaz.

.PARAMETER Gun
    Olay taraması için gün sayısı. Varsayılan 14.

.EXAMPLE
    .\depolama-sagligi.ps1
    .\depolama-sagligi.ps1 -Gun 30

.NOTES
    bilgince.com — Hızlı Çözümler
    Yönetici olarak çalıştırın; güvenilirlik sayaçları aksi hâlde okunmaz.
#>

[CmdletBinding()]
param([int]$Gun = 14)

$ErrorActionPreference = 'SilentlyContinue'
$uyarilar = @()

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}
function Uyar { param([string]$M) $script:uyarilar += $M }

Yaz "=== Depolama sağlık raporu — $env:COMPUTERNAME — $(Get-Date -f 'dd.MM.yyyy HH:mm') ===" Baslik

# ------------------------------------------------------- 1. fiziksel disk
Yaz "`n--- 1. Fiziksel diskler ---" Baslik
$diskler = Get-PhysicalDisk
if ($diskler) {
    $diskler | Select-Object DeviceId, FriendlyName, MediaType, BusType,
        @{n='Boyut_GB';e={[math]::Round($_.Size/1GB)}}, HealthStatus, OperationalStatus |
        Format-Table -AutoSize

    foreach ($d in $diskler) {
        if ($d.HealthStatus -ne 'Healthy') {
            Yaz "$($d.FriendlyName): sağlık $($d.HealthStatus)" Hata
            Uyar "$($d.FriendlyName) sağlık durumu $($d.HealthStatus) — diski değiştirmeye hazırlanın."
        }
    }
} else {
    Yaz 'Fiziksel disk bilgisi okunamadı (donanım RAID arkasında olabilir).' Uyari
    Yaz 'RAID denetleyicisi diskleri gizliyorsa üreticinin aracıyla ayrıca bakın.' Bilgi
}

# ------------------------------------------------- 2. güvenilirlik sayaçları
Yaz "`n--- 2. Güvenilirlik sayaçları ---" Baslik
foreach ($d in $diskler) {
    $s = $d | Get-StorageReliabilityCounter
    if (-not $s) { continue }

    $satir = "{0,-30} okuma hatası: {1,-6} yazma hatası: {2,-6} yeniden konumlanan: {3,-6} sıcaklık: {4}" -f
        $d.FriendlyName, ($s.ReadErrorsTotal ?? '-'), ($s.WriteErrorsTotal ?? '-'),
        ($s.ReadErrorsUncorrected ?? '-'), $(if ($s.Temperature) { "$($s.Temperature)°C" } else { '-' })
    $tur = 'Bilgi'

    if ($s.ReadErrorsUncorrected -gt 0) {
        $tur = 'Hata'
        Uyar "$($d.FriendlyName): düzeltilemeyen $($s.ReadErrorsUncorrected) okuma hatası — veri kaybı başlamış olabilir."
    } elseif (($s.ReadErrorsTotal + $s.WriteErrorsTotal) -gt 100) {
        $tur = 'Uyari'
        Uyar "$($d.FriendlyName): toplam hata sayısı yüksek; eğilimi izleyin."
    }
    if ($s.Temperature -gt 55) {
        $tur = 'Uyari'
        Uyar "$($d.FriendlyName): $($s.Temperature)°C — havalandırmayı kontrol edin."
    }
    if ($s.PowerOnHours) {
        $yil = [math]::Round($s.PowerOnHours / 8760, 1)
        $satir += "  çalışma: $yil yıl"
        if ($yil -gt 5) { Uyar "$($d.FriendlyName): $yil yıldır çalışıyor — değişim planına alın." }
    }
    Yaz "  $satir" $tur
}

# --------------------------------------------------- 3. havuz / sanal disk
Yaz "`n--- 3. Depolama havuzları ---" Baslik
$havuzlar = Get-StoragePool | Where-Object IsPrimordial -eq $false
if ($havuzlar) {
    $havuzlar | Select-Object FriendlyName, HealthStatus, OperationalStatus,
        @{n='Boyut_GB';e={[math]::Round($_.Size/1GB)}},
        @{n='Bos_GB';e={[math]::Round(($_.Size - $_.AllocatedSize)/1GB)}} | Format-Table -AutoSize

    Get-VirtualDisk | Select-Object FriendlyName, ResiliencySettingName, HealthStatus,
        OperationalStatus, @{n='Boyut_GB';e={[math]::Round($_.Size/1GB)}} | Format-Table -AutoSize

    foreach ($v in Get-VirtualDisk | Where-Object HealthStatus -ne 'Healthy') {
        Yaz "$($v.FriendlyName): $($v.HealthStatus) / $($v.OperationalStatus)" Hata
        Uyar "Sanal disk $($v.FriendlyName) sağlıklı değil."
    }
} else {
    Yaz 'Depolama Alanları havuzu yok.' Bilgi
}

# ------------------------------------------------------------- 4. birimler
Yaz "`n--- 4. Birimler ---" Baslik
Get-Volume | Where-Object DriveLetter |
    Select-Object DriveLetter, FileSystemLabel, FileSystem, HealthStatus,
        @{n='Boyut_GB';e={[math]::Round($_.Size/1GB,1)}},
        @{n='Bos_GB';e={[math]::Round($_.SizeRemaining/1GB,1)}},
        @{n='Doluluk';e={ if ($_.Size) { "%$([math]::Round(($_.Size-$_.SizeRemaining)/$_.Size*100))" } }} |
    Format-Table -AutoSize

foreach ($v in Get-Volume | Where-Object { $_.DriveLetter -and $_.Size }) {
    $doluluk = ($v.Size - $v.SizeRemaining) / $v.Size
    if ($doluluk -gt 0.9) { Uyar "$($v.DriveLetter): sürücüsü %$([math]::Round($doluluk*100)) dolu." }
    if ($v.HealthStatus -ne 'Healthy') { Uyar "$($v.DriveLetter): birim sağlığı $($v.HealthStatus)." }
}

# --------------------------------------------------------- 5. disk olayları
Yaz "`n--- 5. Son $Gun günde disk olayları ---" Baslik
$olaylar = Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    Id        = 7, 9, 11, 15, 51, 55, 98, 129, 153, 157
    StartTime = (Get-Date).AddDays(-$Gun)
} -MaxEvents 60

$anlam = @{
    7 = 'Kötü blok'; 9 = 'Aygıt zaman aşımı'; 11 = 'Denetleyici hatası'; 15 = 'Aygıt hazır değil'
    51 = 'Sayfalama hatası'; 55 = 'NTFS bozulması'; 98 = 'Birim kurtarma'
    129 = 'Denetleyici sıfırlandı'; 153 = 'G/Ç yeniden denendi'; 157 = 'Disk beklenmedik biçimde kaldırıldı'
}

if ($olaylar) {
    $olaylar | Group-Object Id | Sort-Object Count -Descending | ForEach-Object {
        $kimlik = [int]$_.Name
        Yaz ("  {0,-5} {1,-28} {2} kez" -f $kimlik, $anlam[$kimlik], $_.Count) Hata
        Uyar "Olay $kimlik ($($anlam[$kimlik])) $($_.Count) kez görüldü."
    }
    $son = $olaylar | Sort-Object TimeCreated -Descending | Select-Object -First 3
    Yaz "`nSon üç olay:"
    $son | ForEach-Object { Yaz ("  {0}  {1}" -f $_.TimeCreated, ($_.Message -split "`n")[0]) }
} else {
    Yaz "Son $Gun günde disk olayı yok." Iyi
}

# ------------------------------------------------------------- 6. gölge kopya
Yaz "`n--- 6. Gölge kopya alanı ---" Baslik
vssadmin list shadowstorage 2>&1 | Select-String 'For volume|Used|Allocated|Maximum' |
    ForEach-Object { Yaz "  $($_.ToString().Trim())" }

# ------------------------------------------------------------------ sonuç
Yaz "`n=== Sonuç ===" Baslik
if (-not $uyarilar) {
    Yaz 'Depolama tarafında dikkat çeken bir bulgu yok.' Iyi
} else {
    Yaz "$($uyarilar.Count) bulgu:" Uyari
    $uyarilar | ForEach-Object { Yaz "  • $_" Uyari }
    Yaz "`nSıra:" Bilgi
    Yaz '  1. Yedeği doğrulayın — disk değiştirmeden önce yapılacak ilk iş budur'
    Yaz '  2. Düzeltilemeyen hata varsa diski üretimden çıkarın, chkdsk ile uğraşmayın'
    Yaz '  3. RAID varsa yeniden yapılandırma süresini hesaba katın (raid-hesaplayici aracı)'
    Yaz '  4. Aynı parti disklerin hepsini izleyin: birlikte alınan diskler birlikte ölür'
}
