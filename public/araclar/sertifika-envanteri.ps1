<#
.SYNOPSIS
    Makinedeki sertifikaları, süresini ve IIS bağlamalarını tek raporda çıkarır.

.DESCRIPTION
    Sertifika süresinin dolması, önceden bilinebilecek tek arıza türüdür — yine de
    en sık yaşananlardandır, çünkü kimse envanteri tutmaz. Bu betik makine ve
    kullanıcı depolarındaki sertifikaları listeler, süresi yaklaşanları işaretler,
    IIS varsa hangi sitenin hangi sertifikayı kullandığını eşleştirir ve zinciri
    eksik olanları söyler.

    Değişiklik yapmaz. Birden çok sunucudan CSV toplamak için -Csv kullanın.

.PARAMETER Gun
    Kaç gün içinde dolacaklar vurgulanacak. Varsayılan 45.

.PARAMETER Csv
    Sonucu nesne olarak döndürür.

.EXAMPLE
    .\sertifika-envanteri.ps1
    .\sertifika-envanteri.ps1 -Gun 90 -Csv | Export-Csv .\sertifikalar.csv -NoTypeInformation -Encoding UTF8

.NOTES
    bilgince.com — Hızlı Çözümler
#>

[CmdletBinding()]
param(
    [int]$Gun = 45,
    [switch]$Csv
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

Yaz "=== Sertifika envanteri — $env:COMPUTERNAME — $(Get-Date -f 'dd.MM.yyyy') ===" Baslik

$depolar = @(
    'Cert:\LocalMachine\My',
    'Cert:\LocalMachine\WebHosting',
    'Cert:\CurrentUser\My'
)

$hepsi = foreach ($depo in $depolar) {
    Get-ChildItem $depo -ErrorAction SilentlyContinue | ForEach-Object {
        $kalan = [int]($_.NotAfter - (Get-Date)).TotalDays
        [pscustomobject]@{
            Depo        = $depo.Replace('Cert:\', '')
            Konu        = ($_.Subject -replace '^CN=', '') -replace ',.*$', ''
            Veren       = ($_.Issuer -replace '^CN=', '') -replace ',.*$', ''
            Baslangic   = $_.NotBefore
            Bitis       = $_.NotAfter
            KalanGun    = $kalan
            Algoritma   = $_.SignatureAlgorithm.FriendlyName
            AnahtarBit  = $_.PublicKey.Key.KeySize
            OzelAnahtar = $_.HasPrivateKey
            Parmakizi   = $_.Thumbprint
            SAN         = (($_.Extensions | Where-Object { $_.Oid.FriendlyName -eq 'Subject Alternative Name' }).Format(0))
        }
    }
}

if (-not $hepsi) {
    Yaz 'Hiç sertifika bulunamadı (yönetici hakkı gerekebilir).' Uyari
    return
}

# ------------------------------------------------------- 1. süresi yaklaşanlar
Yaz "`n--- 1. Süresi dolmuş ve $Gun gün içinde dolacaklar ---" Baslik
$acil = $hepsi | Where-Object { $_.KalanGun -lt $Gun } | Sort-Object KalanGun
if ($acil) {
    $acil | Select-Object Konu, Veren, Bitis, KalanGun, Depo | Format-Table -AutoSize
    foreach ($s in $acil) {
        if ($s.KalanGun -lt 0) { Yaz "  SÜRESİ DOLDU: $($s.Konu) — $([math]::Abs($s.KalanGun)) gün önce" Hata }
        else { Yaz "  $($s.KalanGun) gün: $($s.Konu)" Uyari }
    }
} else {
    Yaz "$Gun gün içinde dolacak sertifika yok." Iyi
}

# ------------------------------------------------------------ 2. tüm envanter
Yaz "`n--- 2. Tüm sertifikalar ---" Baslik
$hepsi | Sort-Object KalanGun |
    Select-Object Konu, Veren, KalanGun, AnahtarBit, OzelAnahtar, Depo |
    Format-Table -AutoSize

# ------------------------------------------------------------ 3. zayıflıklar
Yaz "--- 3. Zayıf sertifikalar ---" Baslik
$zayif = $hepsi | Where-Object { $_.Algoritma -match 'sha1' -or ($_.AnahtarBit -and $_.AnahtarBit -lt 2048) }
if ($zayif) {
    $zayif | Select-Object Konu, Algoritma, AnahtarBit | Format-Table -AutoSize
    Yaz 'SHA-1 imzalı ya da 2048 bitin altında anahtarı olan sertifikalar tarayıcılarca reddedilir.' Uyari
} else {
    Yaz 'SHA-1 ya da kısa anahtarlı sertifika yok.' Iyi
}

# ---------------------------------------------------------------- 4. IIS
Yaz "`n--- 4. IIS bağlamaları ---" Baslik
if (Get-Module -ListAvailable -Name WebAdministration) {
    Import-Module WebAdministration
    $baglamalar = Get-ChildItem IIS:\SslBindings -ErrorAction SilentlyContinue
    if ($baglamalar) {
        foreach ($b in $baglamalar) {
            $sertifika = $hepsi | Where-Object Parmakizi -eq $b.Thumbprint | Select-Object -First 1
            $ad = if ($sertifika) { "$($sertifika.Konu) ($($sertifika.KalanGun) gün)" } else { 'depoda bulunamadı' }
            Yaz ("  {0}:{1}  →  {2}" -f $b.IPAddress, $b.Port, $ad) `
                $(if ($sertifika -and $sertifika.KalanGun -lt $Gun) { 'Uyari' } elseif ($sertifika) { 'Iyi' } else { 'Hata' })
        }
    } else {
        Yaz '  SSL bağlaması yok.' Bilgi
    }
} else {
    Yaz '  IIS kurulu değil, bu bölüm atlandı.' Bilgi
}

# -------------------------------------------------------------- 5. zincir
Yaz "`n--- 5. Zincir kontrolü (özel anahtarı olanlar) ---" Baslik
foreach ($s in $hepsi | Where-Object OzelAnahtar) {
    $sertifika = Get-ChildItem "Cert:\$($s.Depo)" | Where-Object Thumbprint -eq $s.Parmakizi
    $zincir = [Security.Cryptography.X509Certificates.X509Chain]::new()
    $gecerli = $zincir.Build($sertifika)
    if ($gecerli) {
        Yaz "  $($s.Konu): zincir tam ($($zincir.ChainElements.Count) sertifika)" Iyi
    } else {
        $sebep = ($zincir.ChainStatus | ForEach-Object { $_.StatusInformation.Trim() }) -join '; '
        Yaz "  $($s.Konu): ZİNCİR SORUNLU — $sebep" Hata
        Yaz '    Eksik ara sertifika en sık görülen yapılandırma hatasıdır; sunucu zinciri tam göndermelidir.' Bilgi
    }
    $zincir.Dispose()
}

Yaz "`n--- Özet ---" Baslik
Yaz "Toplam $($hepsi.Count) sertifika · $(($hepsi | Where-Object KalanGun -lt 0).Count) süresi dolmuş · $(($acil | Where-Object KalanGun -ge 0).Count) yaklaşan"
Yaz 'Yenileme takvimini bu listeden çıkarın; hatırlatma kurmadan geçirmeyin.'

if ($Csv) { $hepsi | Select-Object @{n='Makine';e={$env:COMPUTERNAME}}, * }
