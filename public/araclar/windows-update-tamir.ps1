<#
.SYNOPSIS
    Windows Update hata veriyorsa önce teşhis, istenirse bileşen onarımı yapar.

.DESCRIPTION
    Varsayılan olarak hiçbir şey değiştirmez: servis durumlarını, son güncelleme
    geçmişini, hata kodlarını, disk alanını ve WSUS/ilke yönlendirmesini raporlar.
    -Onar verildiğinde Windows Update bileşenlerini sıfırlar: servisleri durdurur,
    indirme önbelleğini (SoftwareDistribution) ve imza deposunu (catroot2) yeniden
    adlandırır, servisleri geri başlatır.

    Önbelleği yeniden adlandırmak veri kaybettirmez; Windows onları yeniden kurar.
    Yalnızca bekleyen indirmeler baştan iner.

.PARAMETER Onar
    Teşhisten sonra bileşen sıfırlamayı da uygular. Yönetici hakkı ister.

.EXAMPLE
    .\windows-update-tamir.ps1
    .\windows-update-tamir.ps1 -Onar

.NOTES
    bilgince.com — Hızlı Çözümler
#>

[CmdletBinding()]
param(
    [switch]$Onar
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

$yonetici = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

Yaz "=== Windows Update teşhis — $(Get-Date -f 'dd.MM.yyyy HH:mm') ===" Baslik
Yaz ("Yönetici: {0}" -f $(if ($yonetici) { 'evet' } else { 'HAYIR — onarım yapılamaz' })) $(if ($yonetici) { 'Iyi' } else { 'Uyari' })

# --------------------------------------------------------------- 1. servisler
Yaz "`n--- 1. Servisler ---" Baslik
$servisler = 'wuauserv', 'bits', 'cryptsvc', 'msiserver', 'trustedinstaller'
Get-Service $servisler | Select-Object Name, Status, StartType | Format-Table -AutoSize

$kapali = Get-Service $servisler | Where-Object { $_.StartType -eq 'Disabled' }
if ($kapali) {
    Yaz "Devre dışı bırakılmış servis var: $($kapali.Name -join ', ')" Hata
    Yaz 'Bir "optimizasyon" aracı ya da ilke kapatmış olabilir. Onarımdan önce açılmalı.' Uyari
}

# ------------------------------------------------------------- 2. son geçmiş
Yaz "`n--- 2. Son güncelleme geçmişi ---" Baslik
$oturum = New-Object -ComObject Microsoft.Update.Session
$arayici = $oturum.CreateUpdateSearcher()
$adet = $arayici.GetTotalHistoryCount()
if ($adet -gt 0) {
    $arayici.QueryHistory(0, [Math]::Min(10, $adet)) |
        Select-Object Date,
            @{ n = 'Sonuc'; e = { @{ 0 = '?'; 1 = 'devam'; 2 = 'BASARILI'; 3 = 'uyarili'; 4 = 'BASARISIZ'; 5 = 'iptal' }[[int]$_.ResultCode] } },
            @{ n = 'Kod'; e = { '0x{0:X8}' -f $_.HResult } },
            @{ n = 'Baslik'; e = { $_.Title.Substring(0, [Math]::Min(60, $_.Title.Length)) } } |
        Format-Table -AutoSize
} else {
    Yaz 'Güncelleme geçmişi boş — bileşen zaten sıfırlanmış ya da hiç çalışmamış.' Uyari
}

# yaygın hata kodlarının anlamı
$kodlar = @{
    '0x80070005' = 'Erişim engellendi — ilke ya da izin sorunu'
    '0x8024402C' = 'Ağ/proxy: güncelleme sunucusuna ulaşılamıyor'
    '0x80244022' = 'Sunucu meşgul ya da WSUS yanıt vermiyor'
    '0x80070020' = 'Dosya başka bir süreç tarafından kilitli (genelde antivirüs)'
    '0x800F0922' = 'Sistem ayrılmış bölümü küçük ya da .NET güncellemesi takıldı'
    '0x80073712' = 'Bileşen deposu bozuk — DISM /RestoreHealth gerekir'
    '0x800F081F' = 'Kaynak dosya bulunamadı — DISM için kaynak belirtin'
}
Yaz "`nSık görülen kodlar:" Bilgi
$kodlar.GetEnumerator() | Sort-Object Name | ForEach-Object { Yaz ("  {0}  {1}" -f $_.Key, $_.Value) }

# ------------------------------------------------------------- 3. yönlendirme
Yaz "`n--- 3. WSUS / ilke yönlendirmesi ---" Baslik
$au = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
if (Test-Path $au) {
    Get-ItemProperty $au | Select-Object WUServer, WUStatusServer, DoNotConnectToWindowsUpdateInternetLocations |
        Format-List
    Yaz 'İlke ile bir güncelleme sunucusuna yönlendirilmiş. Sunucu erişilemezse istemci hiçbir yerden güncelleme alamaz.' Uyari
} else {
    Yaz 'İlke yönlendirmesi yok — doğrudan Microsoft Update kullanılıyor.' Iyi
}

# ----------------------------------------------------------------- 4. alan
Yaz "`n--- 4. Disk alanı ---" Baslik
$sistem = Get-PSDrive C
$bosGB = [math]::Round($sistem.Free / 1GB, 1)
Yaz "C: boş alan: $bosGB GB" $(if ($bosGB -lt 10) { 'Hata' } elseif ($bosGB -lt 20) { 'Uyari' } else { 'Iyi' })
if ($bosGB -lt 20) {
    Yaz 'Özellik güncellemeleri 20 GB civarı boş alan ister. Alan açmadan onarım da işe yaramaz.' Uyari
}

$sd = 'C:\Windows\SoftwareDistribution'
if (Test-Path $sd) {
    $boyut = [math]::Round((Get-ChildItem $sd -Recurse -File | Measure-Object Length -Sum).Sum / 1GB, 2)
    Yaz "SoftwareDistribution önbelleği: $boyut GB"
}

# --------------------------------------------------------------- 5. onarım
if (-not $Onar) {
    Yaz "`n--- Sonraki adım ---" Baslik
    Yaz 'Bu çalıştırma hiçbir şey değiştirmedi.'
    Yaz 'Bileşen sıfırlamak için yönetici olarak:  .\windows-update-tamir.ps1 -Onar'
    Yaz 'Bileşen deposu bozuksa önce:  DISM /Online /Cleanup-Image /RestoreHealth'
    return
}

if (-not $yonetici) {
    Yaz "`nOnarım için yönetici hakkı gerekir. PowerShell'i yönetici olarak açın." Hata
    return
}

Yaz "`n--- 5. Bileşen sıfırlama ---" Baslik
$damga = Get-Date -f 'yyyyMMdd-HHmmss'

foreach ($s in 'wuauserv', 'bits', 'cryptsvc', 'msiserver') {
    Stop-Service $s -Force
    Yaz "  durduruldu: $s"
}

foreach ($klasor in 'C:\Windows\SoftwareDistribution', 'C:\Windows\System32\catroot2') {
    if (Test-Path $klasor) {
        $yeni = "$klasor.eski-$damga"
        Rename-Item $klasor $yeni -ErrorAction SilentlyContinue
        if (Test-Path $yeni) { Yaz "  yeniden adlandırıldı: $klasor" Iyi }
        else { Yaz "  YENIDEN ADLANDIRILAMADI: $klasor (dosya kilitli olabilir)" Hata }
    }
}

# BITS kuyruğundaki yarım işler yeni önbellekle uyuşmaz
bitsadmin /reset /allusers 2>&1 | Out-Null

foreach ($s in 'cryptsvc', 'bits', 'msiserver', 'wuauserv') {
    Start-Service $s
    Yaz "  başlatıldı: $s"
}

Yaz "`nSıfırlama bitti. Şimdi güncellemeleri yeniden arayın:" Iyi
Yaz '  UsoClient StartScan     (ya da Ayarlar > Windows Update > Güncelleştirmeleri denetle)'
Yaz "Eski önbellekler *.eski-$damga adıyla duruyor; bir hafta sonra silebilirsiniz."
