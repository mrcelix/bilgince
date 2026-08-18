<#
.SYNOPSIS
    Bir alan adının e-posta yapılandırmasını DNS üzerinden denetler.

.DESCRIPTION
    "Gönderdiğimiz postalar spama düşüyor" şikâyetinde bakılacak kayıtları tek
    seferde toplar: MX, SPF (ve içindeki DNS sorgu sayısı), DKIM seçicileri,
    DMARC politikası, MTA-STS, TLS-RPT ve alan adının yaşı için SOA.

    Yalnızca DNS sorgusu yapar; hiçbir yere e-posta göndermez, hiçbir ayarı
    değiştirmez.

.PARAMETER Alan
    Denetlenecek alan adı. Örn: ornek.com

.PARAMETER Secici
    Denenecek ek DKIM seçicileri. Yaygın olanlar zaten denenir.

.EXAMPLE
    .\eposta-tanilama.ps1 -Alan ornek.com
    .\eposta-tanilama.ps1 -Alan ornek.com -Secici 'mail','k1'

.NOTES
    bilgince.com — Hızlı Çözümler
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Alan,
    [string[]]$Secici = @()
)

$ErrorActionPreference = 'SilentlyContinue'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata', 'Baslik')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red'; Baslik = 'Cyan' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

function TxtAl {
    param([string]$Ad)
    (Resolve-DnsName $Ad -Type TXT -ErrorAction SilentlyContinue |
        Where-Object { $_.Strings } | ForEach-Object { $_.Strings -join '' })
}

Yaz "=== E-posta yapılandırma denetimi: $Alan ===" Baslik

# ------------------------------------------------------------------- MX
Yaz "`n--- 1. MX kayıtları ---" Baslik
$mx = Resolve-DnsName $Alan -Type MX -ErrorAction SilentlyContinue | Where-Object NameExchange
if ($mx) {
    $mx | Sort-Object Preference | Select-Object Preference, NameExchange | Format-Table -AutoSize
    if ($mx.NameExchange -match 'outlook.com|office365') { Yaz 'Sağlayıcı: Microsoft 365' Bilgi }
    elseif ($mx.NameExchange -match 'google') { Yaz 'Sağlayıcı: Google Workspace' Bilgi }
} else {
    Yaz 'MX kaydı yok — bu alan adına e-posta teslim edilemez.' Hata
}

# ------------------------------------------------------------------ SPF
Yaz "`n--- 2. SPF ---" Baslik
$spf = TxtAl $Alan | Where-Object { $_ -like 'v=spf1*' }
if (-not $spf) {
    Yaz 'SPF kaydı YOK. Alan adınız adına herkes posta gönderebilir.' Hata
} elseif ($spf.Count -gt 1) {
    Yaz "BİRDEN ÇOK SPF kaydı var ($($spf.Count) adet). RFC bunu hata sayar; ikisi de yok sayılabilir." Hata
    $spf | ForEach-Object { Yaz "  $_" }
} else {
    Yaz "  $spf"
    $sorgular = ([regex]::Matches($spf, '\b(include|a|mx|ptr|exists|redirect)[:=]')).Count
    Yaz "  DNS sorgusu üreten mekanizma: $sorgular / 10" $(if ($sorgular -gt 10) { 'Hata' } elseif ($sorgular -ge 8) { 'Uyari' } else { 'Iyi' })
    if ($sorgular -gt 10) { Yaz '  Sınır aşıldı: SPF permerror verir ve hiç yokmuş gibi davranılır.' Hata }

    if ($spf -match '~all') { Yaz '  Politika: ~all (yumuşak) — geçiş dönemi için uygun.' Uyari }
    elseif ($spf -match '-all') { Yaz '  Politika: -all (sert) — istenen budur.' Iyi }
    elseif ($spf -match '\?all') { Yaz '  Politika: ?all (nötr) — hiçbir koruma sağlamaz.' Hata }

    if ($spf -match '\bptr\b') { Yaz '  ptr mekanizması kullanılmış: yavaş ve güvenilmez, kaldırın.' Uyari }
}

# ----------------------------------------------------------------- DKIM
Yaz "`n--- 3. DKIM seçicileri ---" Baslik
$seciciler = @('selector1', 'selector2', 'google', 'default', 'k1', 'dkim', 's1', 's2', 'mail') + $Secici
$bulunan = 0
foreach ($s in $seciciler | Select-Object -Unique) {
    $ad = "$s._domainkey.$Alan"
    $kayit = Resolve-DnsName $ad -Type CNAME, TXT -ErrorAction SilentlyContinue
    if ($kayit) {
        $bulunan++
        $hedef = ($kayit | Where-Object { $_.NameHost -or $_.Strings } |
            ForEach-Object { if ($_.NameHost) { $_.NameHost } else { ($_.Strings -join '').Substring(0, [Math]::Min(60, ($_.Strings -join '').Length)) + '…' } })
        Yaz "  $s : $hedef" Iyi
    }
}
if (-not $bulunan) {
    Yaz '  Yaygın seçicilerin hiçbirinde DKIM kaydı bulunamadı.' Uyari
    Yaz '  Sağlayıcınızın kullandığı seçiciyi -Secici ile ekleyin; DKIM yoksa DMARC hizalaması SPF''e kalır.' Bilgi
}

# ---------------------------------------------------------------- DMARC
Yaz "`n--- 4. DMARC ---" Baslik
$dmarc = TxtAl "_dmarc.$Alan" | Where-Object { $_ -like 'v=DMARC1*' }
if (-not $dmarc) {
    Yaz 'DMARC kaydı YOK. SPF ve DKIM sonuçlarına göre kimse bir şey yapmıyor.' Hata
} else {
    Yaz "  $dmarc"
    if ($dmarc -match 'p=none') { Yaz '  p=none: yalnızca rapor topluyor, hiçbir mesajı engellemiyor.' Uyari }
    elseif ($dmarc -match 'p=quarantine') { Yaz '  p=quarantine: uyuşmayan mesajlar gereksize düşüyor.' Iyi }
    elseif ($dmarc -match 'p=reject') { Yaz '  p=reject: uyuşmayan mesajlar reddediliyor — hedef budur.' Iyi }
    if ($dmarc -notmatch 'rua=') { Yaz '  rua= yok: rapor toplanmıyor, politikayı sıkılaştırmak için veri olmayacak.' Uyari }
    if ($dmarc -match 'pct=(\d+)' -and [int]$Matches[1] -lt 100) { Yaz "  pct=$($Matches[1]): politika mesajların yalnızca bu yüzdesine uygulanıyor." Uyari }
}

# ------------------------------------------------------------ MTA-STS / TLS
Yaz "`n--- 5. Taşıma güvenliği ---" Baslik
$mtaSts = TxtAl "_mta-sts.$Alan"
Yaz "  MTA-STS: $(if ($mtaSts) { $mtaSts } else { 'yok' })" $(if ($mtaSts) { 'Iyi' } else { 'Bilgi' })
$tlsRpt = TxtAl "_smtp._tls.$Alan"
Yaz "  TLS-RPT: $(if ($tlsRpt) { $tlsRpt } else { 'yok' })" $(if ($tlsRpt) { 'Iyi' } else { 'Bilgi' })

# ------------------------------------------------------------------ özet
Yaz "`n--- Özet ---" Baslik
$eksik = @()
if (-not $spf) { $eksik += 'SPF' }
if (-not $bulunan) { $eksik += 'DKIM' }
if (-not $dmarc) { $eksik += 'DMARC' }

if ($eksik) {
    Yaz "Eksik kayıtlar: $($eksik -join ', ')" Hata
    Yaz 'Sıra: önce SPF ve DKIM, sonra DMARC p=none, iki hafta rapor, sonra quarantine, sonra reject.'
} else {
    Yaz 'Üç kayıt da var. Sıradaki adım DMARC politikasını sıkılaştırmak.' Iyi
}
Yaz 'Kayıt üretmek için: https://www.bilgince.com/araclar/eposta-guvenlik-kayitlari'
