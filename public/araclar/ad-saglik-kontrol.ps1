<#
.SYNOPSIS
    Active Directory ortamının sağlığını tek raporda çıkarır.

.DESCRIPTION
    AD sorunları nadiren "AD bozuk" diye görünür: oturum açılmaz, ilke gelmez,
    parola değişikliği bir yerde geçerli olur diğerinde olmaz. Hepsinin altında
    aynı üç şey vardır — çoğaltma, zaman ve FSMO.

    Bu betik sırayla bakar: denetleyici envanteri, çoğaltma gecikmeleri, FSMO rol
    sahipleri, SYSVOL/DFSR durumu, zaman hiyerarşisi, çöp kutusu, işlevsel
    seviyeler ve ayrıcalıklı grup üyelikleri.

    Değişiklik yapmaz.

.PARAMETER Gun
    Parola ve nesne yaşı denetimlerinde kullanılacak eşik. Varsayılan 90.

.EXAMPLE
    .\ad-saglik-kontrol.ps1
    .\ad-saglik-kontrol.ps1 -Gun 180

.NOTES
    bilgince.com — Hızlı Çözümler
    ActiveDirectory modülü (RSAT) gerekir; etki alanı yöneticisi hakkı önerilir.
#>

[CmdletBinding()]
param([int]$Gun = 90)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Yaz 'ActiveDirectory modülü yok. RSAT kurun ya da bir denetleyicide çalıştırın.' Hata
    return
}
Import-Module ActiveDirectory

$alan = Get-ADDomain
$orman = Get-ADForest
Yaz "=== Active Directory sağlık raporu — $($alan.DNSRoot) — $(Get-Date -f 'dd.MM.yyyy HH:mm') ===" Baslik

# ------------------------------------------------------- 1. denetleyiciler
Yaz "`n--- 1. Etki alanı denetleyicileri ---" Baslik
$dcler = Get-ADDomainController -Filter *
$dcler | Select-Object Name, Site, IPv4Address, OperatingSystem, IsGlobalCatalog, IsReadOnly |
    Format-Table -AutoSize

foreach ($dc in $dcler) {
    $erisim = Test-Connection $dc.HostName -Count 1 -Quiet
    Yaz ("  {0,-20} {1}" -f $dc.Name, $(if ($erisim) { 'erişilebilir' } else { 'ERİŞİLEMİYOR' })) `
        $(if ($erisim) { 'Iyi' } else { 'Hata' })
}
if (($dcler | Where-Object IsGlobalCatalog).Count -eq 0) {
    Yaz 'Genel katalog sunucusu yok — oturum açma ve Exchange sorguları çalışmaz.' Hata
}
if ($dcler.Count -eq 1) {
    Yaz 'Tek denetleyici var: bu makine tek arıza noktasıdır.' Uyari
}

# --------------------------------------------------------- 2. çoğaltma
Yaz "`n--- 2. Çoğaltma ---" Baslik
$hatalar = repadmin /showrepl * /csv 2>$null | ConvertFrom-Csv
if ($hatalar) {
    $sorunlu = $hatalar | Where-Object { [int]$_.'Number of Failures' -gt 0 }
    if ($sorunlu) {
        $sorunlu | Select-Object 'Source DSA', 'Destination DSA', 'Number of Failures', 'Last Failure Status' |
            Format-Table -AutoSize
        Yaz "$($sorunlu.Count) çoğaltma bağlantısında hata var." Hata
        Yaz 'Çoğaltma durursa parola değişiklikleri ve grup üyelikleri denetleyiciler arasında yayılmaz.' Uyari
    } else {
        Yaz "Tüm çoğaltma bağlantıları başarılı ($($hatalar.Count) bağlantı)." Iyi
    }
} else {
    Yaz 'repadmin çıktısı okunamadı (yetki ya da araç eksikliği).' Uyari
}

# ------------------------------------------------------------- 3. FSMO
Yaz "`n--- 3. FSMO rolleri ---" Baslik
$roller = [ordered]@{
    'Şema yöneticisi'          = $orman.SchemaMaster
    'Alan adlandırma'          = $orman.DomainNamingMaster
    'PDC öykünücüsü'           = $alan.PDCEmulator
    'RID havuzu'               = $alan.RIDMaster
    'Altyapı'                  = $alan.InfrastructureMaster
}
$roller.GetEnumerator() | ForEach-Object {
    $canli = Test-Connection ($_.Value -replace '\..*$', '') -Count 1 -Quiet
    Yaz ("  {0,-24} {1}  {2}" -f $_.Key, $_.Value, $(if ($canli) { '' } else { '← ERİŞİLEMİYOR' })) `
        $(if ($canli) { 'Bilgi' } else { 'Hata' })
}
Yaz 'PDC öykünücüsü erişilemezse: hesap kilitleri, parola değişiklikleri ve zaman kaynağı etkilenir.' Bilgi

# --------------------------------------------------------- 4. SYSVOL / DFSR
Yaz "`n--- 4. SYSVOL çoğaltması ---" Baslik
$sysvol = "\\$($alan.DNSRoot)\SYSVOL\$($alan.DNSRoot)\Policies"
Yaz "SYSVOL erişimi: $(if (Test-Path $sysvol) { 'var' } else { 'YOK' })" $(if (Test-Path $sysvol) { 'Iyi' } else { 'Hata' })

$dfsr = Get-CimInstance -Namespace root\microsoftdfs -ClassName dfsrreplicatedfolderinfo -ErrorAction SilentlyContinue
if ($dfsr) {
    $dfsr | Select-Object ReplicationGroupName, ReplicatedFolderName, State | Format-Table -AutoSize
    foreach ($d in $dfsr | Where-Object State -ne 4) {
        Yaz "  $($d.ReplicatedFolderName): durum $($d.State) (4 = normal)" Uyari
    }
} else {
    Yaz '  DFSR durumu okunamadı (yalnızca denetleyicide çalışır).' Bilgi
}

# ------------------------------------------------------------- 5. zaman
Yaz "`n--- 5. Zaman hiyerarşisi ---" Baslik
$kaynak = w32tm /query /source 2>$null
Yaz "Bu makinenin zaman kaynağı: $kaynak"
$pdcAd = $alan.PDCEmulator -replace '\..*$', ''
$pdcKaynak = w32tm /query /computer:$pdcAd /source 2>$null
Yaz "PDC öykünücüsünün kaynağı: $pdcKaynak"
if ($pdcKaynak -match 'Local CMOS Clock|Free-running') {
    Yaz 'PDC dış bir zaman kaynağına bağlı değil: tüm etki alanı yavaşça kayar.' Hata
    Yaz '  w32tm /config /manualpeerlist:"tr.pool.ntp.org" /syncfromflags:manual /reliable:yes /update' Bilgi
}

foreach ($dc in $dcler) {
    $uzak = (Get-CimInstance Win32_OperatingSystem -ComputerName $dc.HostName).LocalDateTime
    if ($uzak) {
        $fark = [math]::Abs(((Get-Date) - $uzak).TotalMinutes)
        Yaz ("  {0,-20} fark {1:N1} dakika" -f $dc.Name, $fark) $(if ($fark -lt 2) { 'Iyi' } elseif ($fark -lt 5) { 'Uyari' } else { 'Hata' })
    }
}

# ------------------------------------------------------ 6. yapılandırma
Yaz "`n--- 6. Yapılandırma ---" Baslik
Yaz "Orman işlevsel seviyesi: $($orman.ForestMode)"
Yaz "Alan işlevsel seviyesi : $($alan.DomainMode)"

$copKutusu = Get-ADOptionalFeature -Filter { Name -eq 'Recycle Bin Feature' }
$acik = $copKutusu.EnabledScopes.Count -gt 0
Yaz "AD çöp kutusu: $(if ($acik) { 'açık' } else { 'KAPALI' })" $(if ($acik) { 'Iyi' } else { 'Uyari' })
if (-not $acik) {
    Yaz '  Yanlışlıkla silinen nesneyi geri almanın tek kolay yolu budur; açmak geri alınamaz ama risksizdir.' Bilgi
}

# ------------------------------------------------- 7. ayrıcalıklı hesaplar
Yaz "`n--- 7. Ayrıcalıklı gruplar ---" Baslik
foreach ($grup in 'Domain Admins', 'Enterprise Admins', 'Schema Admins') {
    $uyeler = Get-ADGroupMember $grup -ErrorAction SilentlyContinue
    if ($null -ne $uyeler) {
        Yaz "  $grup : $($uyeler.Count) üye" $(if ($uyeler.Count -le 3) { 'Iyi' } else { 'Uyari' })
        $uyeler | ForEach-Object { Yaz "    • $($_.Name)" }
    }
}

$eskiParola = Get-ADUser -Filter { Enabled -eq $true } -Properties PasswordLastSet |
    Where-Object { $_.PasswordLastSet -lt (Get-Date).AddDays(-365) }
if ($eskiParola) {
    Yaz "`nBir yıldan eski parolalı etkin hesap: $($eskiParola.Count)" Uyari
}

$pasif = Search-ADAccount -AccountInactive -TimeSpan "$Gun.00:00:00" -UsersOnly |
    Where-Object Enabled -eq $true
if ($pasif) {
    Yaz "$Gun gündür giriş yapmayan etkin hesap: $($pasif.Count)" Uyari
    Yaz 'Kullanılmayan her etkin hesap, saldırgan için kullanılmamış bir anahtardır.' Bilgi
}

Yaz "`n--- Özet ---" Baslik
Yaz 'Çoğaltma hatası      → parola ve grup değişiklikleri yayılmıyor'
Yaz 'PDC erişilemiyor     → kilitler, parola değişiklikleri, zaman kaynağı'
Yaz 'Zaman kayması 5 dk+  → Kerberos reddeder, kimse giremez'
Yaz 'SYSVOL çoğaltmıyor   → grup ilkesi denetleyiciden denetleyiciye farklı'
Yaz 'Çöp kutusu kapalı    → silinen nesne kolay geri gelmez'
