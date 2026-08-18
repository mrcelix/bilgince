<#
.SYNOPSIS
    "Grup ilkesi uygulanmıyor" şikâyetini adım adım daraltır.

.DESCRIPTION
    İlkenin makineye ulaşmasını engelleyen sekiz sebebi sırayla kontrol eder:
    etki alanı bağlantısı, güvenli kanal, DNS, SYSVOL erişimi, son işleme
    zamanı, işleme hataları (olay 1058/1030/1129), WMI süzgeçleri ve güvenlik
    süzmesi. Sonunda tam sonuç raporunu (gpresult) üretir.

    Değişiklik yapmaz; -Yenile verilirse yalnızca ilke yenilemesi tetikler.

.PARAMETER Yenile
    Teşhis sonunda gpupdate /force çalıştırır.

.PARAMETER Rapor
    HTML sonuç raporunu bu yola yazar.

.EXAMPLE
    .\gpo-uygulanmiyor-teshis.ps1
    .\gpo-uygulanmiyor-teshis.ps1 -Yenile -Rapor "$env:USERPROFILE\Desktop\gpo.html"

.NOTES
    bilgince.com — Hızlı Çözümler
    Kullanıcı ilkeleri için o kullanıcının oturumunda çalıştırın.
#>

[CmdletBinding()]
param(
    [switch]$Yenile,
    [string]$Rapor
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

Yaz "=== Grup ilkesi teşhisi — $env:COMPUTERNAME / $env:USERNAME ===" Baslik

# ------------------------------------------------------- 1. etki alanı üyeliği
Yaz "`n--- 1. Etki alanı ve güvenli kanal ---" Baslik
$cs = Get-CimInstance Win32_ComputerSystem
if (-not $cs.PartOfDomain) {
    Yaz 'Makine etki alanında değil — grup ilkesi zaten uygulanmaz.' Hata
    return
}
Yaz "Etki alanı: $($cs.Domain)" Iyi

$kanal = Test-ComputerSecureChannel -Verbose:$false
Yaz "Güvenli kanal: $(if ($kanal) { 'sağlam' } else { 'BOZUK' })" $(if ($kanal) { 'Iyi' } else { 'Hata' })
if (-not $kanal) {
    Yaz 'Onarım: Test-ComputerSecureChannel -Repair -Credential (Get-Credential)' Uyari
    Yaz 'Anlık görüntüden döndürülen makinelerde en sık görülen sebep budur.' Bilgi
}

# ------------------------------------------------------------------- 2. DNS
Yaz "`n--- 2. DNS ve denetleyici ---" Baslik
$dns = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses }).ServerAddresses | Select-Object -Unique
Yaz "Tanımlı DNS: $($dns -join ', ')"

$dc = nltest /dsgetdc:$($cs.Domain) 2>&1
if ($dc -match 'DC: \\\\(\S+)') {
    Yaz "Bulunan denetleyici: $($Matches[1])" Iyi
    $dcAdi = $Matches[1]
} else {
    Yaz 'Etki alanı denetleyicisi bulunamadı. DNS ayarı iç DNS sunucusunu göstermiyor olabilir.' Hata
    Yaz 'Genel DNS (8.8.8.8 gibi) tanımlıysa AD kayıtları çözülemez; grup ilkesi de gelmez.' Uyari
}

# --------------------------------------------------------------- 3. SYSVOL
Yaz "`n--- 3. SYSVOL erişimi ---" Baslik
$sysvol = "\\$($cs.Domain)\SYSVOL\$($cs.Domain)\Policies"
if (Test-Path $sysvol) {
    $adet = (Get-ChildItem $sysvol -Directory).Count
    Yaz "SYSVOL erişilebilir — $adet ilke klasörü" Iyi
} else {
    Yaz "SYSVOL erişilemiyor: $sysvol" Hata
    Yaz 'DFS istemcisi, SMB imzalama uyuşmazlığı ya da ağ erişimi. 1058 olayı bunun karşılığıdır.' Uyari
}

# ------------------------------------------------- 4. son işleme ve hatalar
Yaz "`n--- 4. Son işleme zamanı ---" Baslik
$son = Get-CimInstance -Namespace root\rsop\computer -ClassName RSOP_ExtensionStatus |
    Sort-Object endTime -Descending | Select-Object -First 1
if ($son) {
    Yaz "Son bilgisayar ilkesi işleme: $($son.endTime)"
    $yas = (New-TimeSpan -Start $son.endTime).TotalHours
    if ($yas -gt 24) { Yaz "$([math]::Round($yas)) saattir ilke işlenmemiş — yenileme çalışmıyor olabilir." Uyari }
} else {
    Yaz 'RSOP verisi okunamadı (yönetici hakkı gerekebilir).' Bilgi
}

Yaz "`n--- 5. İşleme hataları (son 7 gün) ---" Baslik
$olaylar = Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    Id        = 1058, 1030, 1129, 1055, 1006
    StartTime = (Get-Date).AddDays(-7)
} -MaxEvents 40

if ($olaylar) {
    $olaylar | Group-Object Id | ForEach-Object {
        $ad = @{
            1058 = 'gpt.ini okunamadı (SYSVOL/DFS)'
            1030 = 'İlke sorgulanamadı'
            1129 = 'Ağ hazır değilken işlendi'
            1055 = 'Bilgisayar adı çözülemedi'
            1006 = 'LDAP bağlanamadı'
        }[[int]$_.Name]
        Yaz ("  {0,-6} {1,-38} {2} kez" -f $_.Name, $ad, $_.Count) Hata
    }
    Yaz "`nSon olay: $($olaylar[0].TimeCreated) — $(($olaylar[0].Message -split "`n")[0])" Bilgi
} else {
    Yaz 'Son 7 günde ilke işleme hatası yok.' Iyi
}

# ------------------------------------------------------ 6. süzgeçler ve kapsam
Yaz "`n--- 6. Uygulanan ve reddedilen ilkeler ---" Baslik
$sonuc = gpresult /r /scope:computer 2>&1
$uygulanan = $false
foreach ($satir in $sonuc) {
    if ($satir -match 'Applied Group Policy Objects|Uygulanan Grup İlkesi') { $uygulanan = $true; Yaz "`n[Uygulanan]" Baslik; continue }
    if ($satir -match 'not applied|uygulanmadı|filtering|Süzme') { Yaz "  $($satir.Trim())" Uyari; continue }
    if ($uygulanan -and $satir.Trim() -and $satir -notmatch '^\s*$') { Yaz "  $($satir.Trim())" Iyi }
    if ($satir -match 'The following GPOs were not applied|Aşağıdaki') { $uygulanan = $false }
}

Yaz "`nSüzme sebepleri şu üç yerden gelir:" Bilgi
Yaz '  • Güvenlik süzmesi: ilkenin "Uygula" iznine sahip olmayan hesap/gruplar'
Yaz '  • WMI süzgeci: sorgu bu makinede false dönüyor'
Yaz '  • Kapsam: makine/kullanıcı ilkenin bağlı olduğu OU altında değil'

# --------------------------------------------------------- 7. WMI süzgeçleri
Yaz "`n--- 7. WMI süzgeç sınaması ---" Baslik
Yaz 'Yaygın süzgeç sorgularını bu makinede deneyin; false dönen ilke uygulanmaz:'
$sorgular = @(
    'SELECT * FROM Win32_OperatingSystem WHERE ProductType = 1',
    'SELECT * FROM Win32_OperatingSystem WHERE ProductType = 3',
    'SELECT * FROM Win32_ComputerSystem WHERE Model LIKE "%Virtual%"'
)
foreach ($s in $sorgular) {
    $r = Get-CimInstance -Query $s -ErrorAction SilentlyContinue
    Yaz ("  {0,-62} → {1}" -f $s, $(if ($r) { 'true' } else { 'false' })) $(if ($r) { 'Iyi' } else { 'Bilgi' })
}

# ----------------------------------------------------------------- rapor
if ($Rapor) {
    gpresult /h $Rapor /f | Out-Null
    Yaz "`nHTML rapor yazıldı: $Rapor" Iyi
}

if ($Yenile) {
    Yaz "`n--- İlke yenileniyor ---" Baslik
    gpupdate /force
}

Yaz "`n--- Özet ---" Baslik
Yaz 'Güvenli kanal bozuk        → Test-ComputerSecureChannel -Repair'
Yaz 'DC bulunamıyor             → DNS ayarı (iç DNS olmalı)'
Yaz 'SYSVOL erişilemiyor        → 1058: DFS, SMB, ağ'
Yaz 'İlke listede ama uygulanmadı → güvenlik süzmesi ya da WMI süzgeci'
Yaz 'Hiç işlenmemiş             → 1129: açılışta ağ hazır değil'
