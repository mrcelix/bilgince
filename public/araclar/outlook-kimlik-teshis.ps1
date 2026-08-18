<#
.SYNOPSIS
    Outlook'un sürekli parola sormasının sebebini kayıt defteri, kimlik
    deposu ve Autodiscover tarafında arar.

.DESCRIPTION
    Beş yeri sırayla kontrol eder: modern kimlik doğrulamayı kapatan kayıt
    defteri anahtarları, Windows kimlik deposundaki bozuk/eski kayıtlar,
    Autodiscover yönlendirmeleri, Outlook profilleri ve WAM (Web Account
    Manager) durumu.

    Varsayılan olarak yalnızca rapor üretir. -KimlikTemizle verildiğinde
    Windows kimlik deposundaki Office/Outlook kayıtlarını siler — Outlook bir
    sonraki açılışta bir kez sorar, doğru parolayla düzelir.

.PARAMETER KimlikTemizle
    Kimlik deposundaki MicrosoftOffice*/MSOpenTech* kayıtlarını siler.

.EXAMPLE
    .\outlook-kimlik-teshis.ps1
    .\outlook-kimlik-teshis.ps1 -KimlikTemizle

.NOTES
    bilgince.com — Hızlı Çözümler
    Kullanıcının kendi oturumunda çalıştırın; kimlik deposu kullanıcıya özeldir.
#>

[CmdletBinding()]
param(
    [switch]$KimlikTemizle
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

Yaz "=== Outlook kimlik teşhisi — $env:USERNAME ===" Baslik

# --------------------------------------------------- 1. modern kimlik doğrulama
Yaz "`n--- 1. Modern kimlik doğrulama anahtarları ---" Baslik

$anahtarlar = @(
    @{ Yol = 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity'; Ad = 'EnableADAL'; Beklenen = 1; Not = '0 ise modern kimlik doğrulama kapalı' }
    @{ Yol = 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity'; Ad = 'DisableADALatopWAMOverride'; Beklenen = 0; Not = '1 ise WAM devre dışı, parola döngüsü tipiktir' }
    @{ Yol = 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity'; Ad = 'DisableAADWAM'; Beklenen = 0; Not = '1 ise Entra ID oturumu paylaşılmaz' }
    @{ Yol = 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover'; Ad = 'ExcludeExplicitO365Endpoint'; Beklenen = 0; Not = '1 ise Exchange Online uç noktası atlanır' }
)

foreach ($a in $anahtarlar) {
    $deger = (Get-ItemProperty -Path $a.Yol -Name $a.Ad -ErrorAction SilentlyContinue).$($a.Ad)
    if ($null -eq $deger) {
        Yaz ("  {0,-32} tanımlı değil (varsayılan)" -f $a.Ad) Iyi
    } elseif ($deger -eq $a.Beklenen) {
        Yaz ("  {0,-32} {1} — beklenen değer" -f $a.Ad, $deger) Iyi
    } else {
        Yaz ("  {0,-32} {1} — {2}" -f $a.Ad, $deger, $a.Not) Hata
    }
}

# ------------------------------------------------------------ 2. kimlik deposu
Yaz "`n--- 2. Windows kimlik deposu ---" Baslik
$kayitlar = cmdkey /list | Select-String 'Hedef|Target' | Where-Object { $_ -match 'Office|Outlook|MicrosoftOffice|MSOpenTech|SSO_POP' }
if ($kayitlar) {
    $kayitlar | ForEach-Object { Yaz "  $($_.ToString().Trim())" }
    Yaz 'Bu kayıtlardan biri eski parolayı tutuyorsa Outlook sürekli sorar ve girilen doğru parola da kabul edilmez.' Uyari
} else {
    Yaz 'Office/Outlook kimliği kayıtlı değil — ilk açılışta soracaktır (normal).' Bilgi
}

# --------------------------------------------------------------- 3. profiller
Yaz "`n--- 3. Outlook profilleri ---" Baslik
$profilYol = 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Profiles'
if (Test-Path $profilYol) {
    $profiller = Get-ChildItem $profilYol | Select-Object -ExpandProperty PSChildName
    Yaz ("  Profil sayısı: {0} ({1})" -f $profiller.Count, ($profiller -join ', '))
    if ($profiller.Count -gt 1) {
        Yaz 'Birden çok profil var. Eski profildeki bozuk hesap, yeni profilde de parola sormasına yol açabilir.' Uyari
    }
} else {
    Yaz '  Profil bulunamadı (Outlook hiç açılmamış olabilir).' Bilgi
}

# ----------------------------------------------------------- 4. Autodiscover
Yaz "`n--- 4. Autodiscover yönlendirmesi ---" Baslik
$ad = 'HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover'
if (Test-Path $ad) {
    Get-ItemProperty $ad | Select-Object -Property * -ExcludeProperty PS* | Format-List
}
$eposta = (Get-ItemProperty "$profilYol\*" -ErrorAction SilentlyContinue).PSChildName
$alan = ($env:USERDNSDOMAIN)
if ($alan) {
    Yaz "  DNS kaydı sınanıyor: autodiscover.$alan"
    $srv = Resolve-DnsName "autodiscover.$alan" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($srv) { Yaz "  → $(if ($srv.NameHost) { $srv.NameHost } else { $srv.IPAddress })" Iyi }
    else { Yaz '  → kayıt yok (Exchange Online kullanılıyorsa sorun değil)' Bilgi }
}

# ------------------------------------------------------------------- 5. WAM
Yaz "`n--- 5. Oturum paylaşımı (WAM) ---" Baslik
$wamKayit = Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\IdentityCRL\TokenBroker' -ErrorAction SilentlyContinue
Yaz ("  Belirteç aracısı kaydı: {0}" -f $(if ($wamKayit) { 'var' } else { 'yok' }))
$dsreg = dsregcmd /status 2>$null
if ($dsreg) {
    $dsreg | Select-String 'AzureAdJoined|WorkplaceJoined|DomainJoined|AzureAdPrt' | ForEach-Object { Yaz "  $($_.ToString().Trim())" }
    if (($dsreg | Select-String 'AzureAdPrt\s*:\s*NO')) {
        Yaz 'AzureAdPrt: NO — cihazın birincil yenileme belirteci yok. Tek oturum açma çalışmaz, Outlook her seferinde sorar.' Hata
    }
}

# ------------------------------------------------------------ kimlik temizleme
if ($KimlikTemizle) {
    Yaz "`n--- Kimlik kayıtları siliniyor ---" Baslik
    $silinecek = cmdkey /list | Select-String 'Target:' | ForEach-Object { ($_ -split 'Target:')[1].Trim() } |
        Where-Object { $_ -match 'MicrosoftOffice|MSOpenTech|SSO_POP|OneDrive' }
    if (-not $silinecek) {
        Yaz 'Silinecek kayıt bulunamadı.' Bilgi
    } else {
        foreach ($k in $silinecek) {
            cmdkey /delete:$k | Out-Null
            Yaz "  silindi: $k" Iyi
        }
        Yaz "`nOutlook'u kapatıp açın; bir kez parola soracak, sonra sormamalı." Iyi
    }
}

Yaz "`n--- Özet ---" Baslik
Yaz 'EnableADAL=0 ya da DisableADALatopWAMOverride=1 → ilkeyi düzeltin, gerisi boşuna'
Yaz 'Kimlik deposunda eski kayıt          → -KimlikTemizle ile silin'
Yaz 'AzureAdPrt: NO                       → cihaz kaydı sorunu; Outlook belirtiyi gösteriyor, sebep değil'
Yaz 'Birden çok profil                    → temiz bir profille sınayın'
Yaz 'Bu betik yalnızca -KimlikTemizle ile değişiklik yapar.'
