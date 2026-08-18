<#
.SYNOPSIS
    "Giriş yapamıyorum" şikâyetinde hesap tarafını ve makine tarafını birlikte
    denetler.

.DESCRIPTION
    Oturum açamamanın sebebi hesapta olabilir (kilit, süresi dolmuş parola,
    oturum açma saati kısıtı, iş istasyonu kısıtı, süresi dolmuş hesap) ya da
    makinede (güvenli kanal, saat kayması, DC erişimi, profil). Bu betik ikisini
    sırayla kontrol eder ve son başarısız oturum açma olaylarını alt koduyla
    birlikte çözer.

    Değişiklik yapmaz.

.PARAMETER Kullanici
    Örnek: ahmet.yilmaz

.EXAMPLE
    .\kullanici-oturum-teshis.ps1 -Kullanici ahmet.yilmaz

.NOTES
    bilgince.com — Hızlı Çözümler
    Hesap kontrolleri için ActiveDirectory modülü (RSAT) gerekir.
#>

[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Kullanici)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

Yaz "=== Oturum açma teşhisi: $Kullanici ===" Baslik

# ------------------------------------------------------------- 1. hesap
Yaz "`n--- 1. Hesap durumu ---" Baslik
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory
    $h = Get-ADUser $Kullanici -Properties LockedOut, Enabled, PasswordExpired, PasswordLastSet,
        AccountExpirationDate, LogonHours, userWorkstations, msDS-UserPasswordExpiryTimeComputed,
        badPwdCount, LastBadPasswordAttempt

    if (-not $h) {
        Yaz "Kullanıcı bulunamadı: $Kullanici" Hata
        return
    }

    $sonuc = [ordered]@{
        Etkin              = $h.Enabled
        Kilitli            = $h.LockedOut
        ParolaSuresiDoldu  = $h.PasswordExpired
        ParolaSonAyar      = $h.PasswordLastSet
        HesapBitis         = $h.AccountExpirationDate
        HataliDeneme       = $h.badPwdCount
        SonHataliDeneme    = $h.LastBadPasswordAttempt
    }
    $sonuc.GetEnumerator() | ForEach-Object { Yaz ("  {0,-20} {1}" -f $_.Key, $_.Value) }

    if (-not $h.Enabled) { Yaz 'Hesap DEVRE DIŞI — sebep bu.' Hata }
    if ($h.LockedOut) { Yaz 'Hesap KİLİTLİ. Kilidin kaynağı için ad-hesap-kilit-teshis.ps1 betiğini çalıştırın.' Hata }
    if ($h.PasswordExpired) { Yaz 'Parolanın süresi dolmuş — kullanıcı değiştirmeden giremez.' Hata }
    if ($h.AccountExpirationDate -and $h.AccountExpirationDate -lt (Get-Date)) {
        Yaz "Hesabın süresi $($h.AccountExpirationDate) tarihinde doldu." Hata
    }

    $bitis = [datetime]::FromFileTime($h.'msDS-UserPasswordExpiryTimeComputed')
    if ($bitis -gt (Get-Date)) {
        Yaz "  Parola bitişi: $bitis ($([math]::Round(($bitis - (Get-Date)).TotalDays)) gün)" Bilgi
    }

    if ($h.userWorkstations) {
        Yaz "  Yalnızca şu makinelerden girebilir: $($h.userWorkstations)" Uyari
        Yaz '  Listede olmayan makineden giriş reddedilir; belirti "parola yanlış" gibi görünür.' Bilgi
    }
    if ($h.LogonHours) {
        Yaz '  Oturum açma saati kısıtı tanımlı — saat dışı denemeler reddedilir.' Uyari
    }
} else {
    Yaz 'ActiveDirectory modülü yok; hesap kontrolleri atlandı (RSAT kurun).' Uyari
}

# ------------------------------------------------------------ 2. makine
Yaz "`n--- 2. Makine tarafı ---" Baslik
$cs = Get-CimInstance Win32_ComputerSystem
Yaz "Etki alanı üyesi: $($cs.PartOfDomain) ($($cs.Domain))"

if ($cs.PartOfDomain) {
    $kanal = Test-ComputerSecureChannel -Verbose:$false
    Yaz "Güvenli kanal: $(if ($kanal) { 'sağlam' } else { 'BOZUK' })" $(if ($kanal) { 'Iyi' } else { 'Hata' })
    if (-not $kanal) {
        Yaz '  Makine hesabı parolası uyuşmuyor: hiç kimse bu makineden etki alanına giremez.' Hata
        Yaz '  Onarım: Test-ComputerSecureChannel -Repair -Credential (Get-Credential)' Bilgi
    }

    # saat kayması: Kerberos 5 dakikadan fazlasını reddeder
    $dc = (nltest /dsgetdc:$($cs.Domain) 2>&1 | Select-String 'DC: \\\\(\S+)').Matches.Groups[1].Value
    if ($dc) {
        $yerel = Get-Date
        $uzak = (Get-CimInstance Win32_OperatingSystem -ComputerName $dc).LocalDateTime
        if ($uzak) {
            $fark = [math]::Abs(($yerel - $uzak).TotalMinutes)
            Yaz ("Saat farkı ({0}): {1:N1} dakika" -f $dc, $fark) $(if ($fark -lt 5) { 'Iyi' } else { 'Hata' })
            if ($fark -ge 5) {
                Yaz '  Kerberos beş dakikadan büyük farkı reddeder. Parola doğru olsa bile giriş olmaz.' Hata
                Yaz '  w32tm /resync ile zamanı eşitleyin.' Bilgi
            }
        }
    }
}

# --------------------------------------------------- 3. başarısız girişler
Yaz "`n--- 3. Son başarısız oturum açma denemeleri ---" Baslik
$altKodlar = @{
    '0xC0000064' = 'Kullanıcı adı yok'
    '0xC000006A' = 'Parola yanlış'
    '0xC0000234' = 'Hesap kilitli'
    '0xC0000072' = 'Hesap devre dışı'
    '0xC000006F' = 'İzin verilen saat dışında'
    '0xC0000070' = 'İzin verilmeyen iş istasyonu'
    '0xC0000071' = 'Parolanın süresi dolmuş'
    '0xC0000193' = 'Hesabın süresi dolmuş'
    '0xC0000133' = 'Saat kayması çok büyük'
    '0xC0000224' = 'Kullanıcı parolayı değiştirmek zorunda'
}

$olaylar = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4625; StartTime = (Get-Date).AddDays(-2) } -MaxEvents 40
$benimkiler = $olaylar | Where-Object { $_.Message -match [regex]::Escape($Kullanici) }

if ($benimkiler) {
    foreach ($o in $benimkiler | Select-Object -First 8) {
        $kod = ([regex]::Match($o.Message, 'Sub Status:\s*(0x[0-9A-Fa-f]+)')).Groups[1].Value
        $anlam = if ($altKodlar.ContainsKey($kod.ToUpper())) { $altKodlar[$kod.ToUpper()] } else { 'bilinmeyen alt kod' }
        $kaynak = ([regex]::Match($o.Message, 'Workstation Name:\s*(\S+)')).Groups[1].Value
        Yaz ("  {0}  {1}  {2}  (kaynak: {3})" -f $o.TimeCreated.ToString('dd.MM HH:mm'), $kod, $anlam, $kaynak) Hata
    }
    Yaz "`nAlt kod, sebebi doğrudan söyler: parola mı, kısıt mı, saat mi." Bilgi
} else {
    Yaz 'Bu makinede son iki günde bu kullanıcıya ait 4625 olayı yok.' Bilgi
    Yaz 'Denemeler başka makinede ya da etki alanı denetleyicisinde kayıtlı olabilir.' Uyari
}

# ------------------------------------------------------------- 4. profil
Yaz "`n--- 4. Kullanıcı profili ---" Baslik
$profiller = Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like "*$Kullanici*" }
if ($profiller) {
    $profiller | Select-Object LocalPath, Special, Loaded,
        @{n='Bozuk';e={ $_.Status -band 1 }},
        @{n='SonKullanim';e={$_.LastUseTime}} | Format-List
    if ($profiller.LocalPath -match '\.bak$|\.\w{3}$') {
        Yaz 'Profil klasörü yeniden adlandırılmış görünüyor — geçici profil sorunu yaşanmış olabilir.' Uyari
    }
} else {
    Yaz 'Bu makinede kullanıcıya ait yerel profil yok (ilk giriş olabilir).' Bilgi
}

Yaz "`n--- Özet ---" Baslik
Yaz 'Hesap kilitli/devre dışı/süresi dolmuş → hesap tarafı, makinede arama'
Yaz 'Güvenli kanal bozuk                    → hiç kimse giremez, makineyi onarın'
Yaz 'Saat farkı 5 dk üstü                   → Kerberos reddeder, parola doğru olsa bile'
Yaz '0xC0000070                             → iş istasyonu kısıtı'
Yaz '0xC000006F                             → oturum açma saati kısıtı'
Yaz 'Hepsi temizse                          → parola gerçekten yanlış ya da profil bozuk'
