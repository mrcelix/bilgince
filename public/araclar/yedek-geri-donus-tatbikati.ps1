<#
.SYNOPSIS
    Geri dönüş tatbikatı için kanıt toplar ve kontrol listesi üretir.

.DESCRIPTION
    Yedeğin çalıştığı ancak geri dönülerek bilinir. Bu betik yedek
    işlerinin son durumunu toplar, en eski başarılı yedeği bulur, kurtarma
    noktası aralığını hesaplar ve tatbikat için doldurulacak bir kontrol
    listesi üretir.

    Değişiklik yapmaz.

.PARAMETER CiktiDosyasi
    Kontrol listesinin yazılacağı dosya.

.EXAMPLE
    .\yedek-geri-donus-tatbikati.ps1 -CiktiDosyasi .\tatbikat.md

.NOTES
    bilgince.com — Hızlı Çözümler
    Yerleşik Windows Server Backup günlüklerini okur. Üçüncü taraf çözümler kendi günlüklerini yazar.
#>

[CmdletBinding()]
param([string]$CiktiDosyasi = ".\yedek-tatbikat-$(Get-Date -Format yyyy-MM-dd).md")

Write-Host "== Son yedek olayları" -ForegroundColor Cyan
$olaylar = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
} -MaxEvents 40 -ErrorAction SilentlyContinue

if (-not $olaylar) {
    Write-Warning "Yedek günlüğü okunamadı. Üçüncü taraf çözüm kullanıyorsanız onun raporuna bakın."
} else {
    $olaylar | Select-Object -First 15 TimeCreated, Id,
        @{ n = 'Sonuc'; e = { if ($_.Id -in 4, 5) { 'Başarılı' } else { 'Dikkat' } } } |
        Format-Table -AutoSize

    $basarili = $olaylar | Where-Object { $_.Id -in 4, 5 }
    if ($basarili) {
        $son = ($basarili | Sort-Object TimeCreated -Descending)[0]
        $yasSaat = [int]((Get-Date) - $son.TimeCreated).TotalHours
        Write-Host "Son başarılı yedek $yasSaat saat önce." -ForegroundColor $(if ($yasSaat -gt 26) { 'Yellow' } else { 'Green' })
    }
}

Write-Host "== Yedek hedefleri" -ForegroundColor Cyan
try {
    Get-WBSummary | Format-List
} catch {
    Write-Host "  Windows Server Backup özeti alınamadı." -ForegroundColor Yellow
}

# Tatbikat kontrol listesi: doldurulup kanıt olarak saklanmak üzere
$liste = @"
# Geri dönüş tatbikatı — $(Get-Date -Format 'dd.MM.yyyy')

Sunucu: $env:COMPUTERNAME
Yapan:  $env:USERNAME

## Kapsam
- [ ] Geri dönülecek sistem/veritabanı seçildi
- [ ] Hedef ortam üretim değil, ayrı bir ortam
- [ ] Kurtarma noktası tarihi not edildi: ____________

## Uygulama
- [ ] Yedek ortamı erişilebilir
- [ ] Geri dönüş başlatıldı — saat: ______
- [ ] Geri dönüş tamamlandı — saat: ______
- [ ] Süre (RTO ölçümü): ______ dakika

## Doğrulama
- [ ] Servis ayağa kalktı
- [ ] Uygulama oturum açıyor
- [ ] Son işlem verisi mevcut (RPO ölçümü): ______ dakika veri kaybı
- [ ] Bağlı sistemler çalışıyor

## Sonuç
- [ ] Tatbikat başarılı
- [ ] Bulunan eksikler: ____________________________
- [ ] Sorumluya iletildi

> Bu dosya kanıttır. Tarihiyle birlikte saklayın.
"@

$liste | Out-File $CiktiDosyasi -Encoding UTF8
Write-Host "Kontrol listesi yazıldı: $CiktiDosyasi" -ForegroundColor Green
Write-Host "Geri dönüş denenmeden yedek stratejisi doğrulanmış sayılmaz." -ForegroundColor Yellow
