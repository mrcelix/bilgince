<#
.SYNOPSIS
    Takılan yazdırma kuyruğunu temizler ve tekrarlıyorsa sebebini gösterir.

.DESCRIPTION
    Yazdırma biriktiricisini durdurur, kuyruk klasörünü temizler ve servisi
    geri başlatır. Ardından sorunun tekrarlama ihtimalini artıran iki şeyi
    raporlar: hatalı durumdaki yazıcılar ve kullanılmayan sürücüler.

.PARAMETER Rapor
    Hiçbir değişiklik yapmaz; yalnızca kuyruk ve yazıcı durumunu gösterir.

.PARAMETER SurucuTemizle
    Hiçbir yazıcı tarafından kullanılmayan sürücüleri de kaldırır.

.EXAMPLE
    .\yazici-kuyruk-sifirla.ps1 -Rapor

.EXAMPLE
    .\yazici-kuyruk-sifirla.ps1

.NOTES
    bilgince.com — Hızlı Çözümler. Yönetici olarak çalıştırın.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Rapor,
    [switch]$SurucuTemizle
)

$ErrorActionPreference = 'Stop'
$KuyrukYolu = Join-Path $env:SystemRoot 'System32\spool\PRINTERS'

function Yaz {
    param([string]$Metin, [ValidateSet('Bilgi', 'Iyi', 'Uyari', 'Hata')][string]$Tur = 'Bilgi')
    $renk = @{ Bilgi = 'Gray'; Iyi = 'Green'; Uyari = 'Yellow'; Hata = 'Red' }[$Tur]
    Write-Host $Metin -ForegroundColor $renk
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Yaz 'Bu betik yönetici olarak çalıştırılmalı.' Hata
    return
}

# --------------------------------------------------------------------- durum
Yaz "`n--- Kuyruktaki işler ---"
$isler = Get-PrintJob -PrinterName * -ErrorAction SilentlyContinue
if ($isler) {
    $isler | Select-Object PrinterName, Id, DocumentName, JobStatus, SubmittedTime | Format-Table -AutoSize
} else {
    Yaz 'Kuyrukta iş görünmüyor.' Bilgi
}

$bekleyenDosya = @(Get-ChildItem $KuyrukYolu -ErrorAction SilentlyContinue)
Yaz "Kuyruk klasöründe $($bekleyenDosya.Count) dosya var."

Yaz "`n--- Yazıcı durumları ---"
$yazicilar = Get-Printer
$yazicilar | Select-Object Name, DriverName, PortName, PrinterStatus | Format-Table -AutoSize

$sorunlu = $yazicilar | Where-Object { $_.PrinterStatus -notin 'Normal', 'Idle' }
if ($sorunlu) {
    Yaz "Sorunlu durumda $($sorunlu.Count) yazıcı var:" Uyari
    $sorunlu | ForEach-Object { Yaz "  - $($_.Name): $($_.PrinterStatus)" Uyari }
}

if ($Rapor) { Yaz "`nRapor modu: hiçbir değişiklik yapılmadı." Bilgi; return }

# -------------------------------------------------------------------- onarım
if ($PSCmdlet.ShouldProcess('Print Spooler', 'Durdur, kuyruğu temizle, başlat')) {
    Yaz "`nBiriktirici durduruluyor…"
    Stop-Service -Name Spooler -Force
    # Servis tam durmadan dosyalar kilitli kalır
    $bekle = 0
    while ((Get-Service Spooler).Status -ne 'Stopped' -and $bekle -lt 10) {
        Start-Sleep -Seconds 1; $bekle++
    }

    $silinen = 0
    Get-ChildItem $KuyrukYolu -ErrorAction SilentlyContinue | ForEach-Object {
        try { Remove-Item $_.FullName -Force; $silinen++ } catch { Yaz "  Silinemedi: $($_.Name)" Uyari }
    }
    Yaz "$silinen dosya temizlendi." Iyi

    Start-Service -Name Spooler
    Yaz 'Biriktirici yeniden başlatıldı.' Iyi
}

# ------------------------------------------------------------ tekrar sebebi
Yaz "`n--- Tekrarlama sebepleri ---"

$kullanilan = $yazicilar.DriverName | Select-Object -Unique
$tumSuruculer = Get-PrinterDriver | Select-Object -ExpandProperty Name
$bostaSurucu = $tumSuruculer | Where-Object { $_ -notin $kullanilan }

if ($bostaSurucu) {
    Yaz "Hiçbir yazıcı tarafından kullanılmayan $($bostaSurucu.Count) sürücü var:" Uyari
    $bostaSurucu | ForEach-Object { Yaz "  - $_" Uyari }
    if ($SurucuTemizle) {
        foreach ($s in $bostaSurucu) {
            if ($PSCmdlet.ShouldProcess($s, 'Sürücüyü kaldır')) {
                try { Remove-PrinterDriver -Name $s; Yaz "  Kaldırıldı: $s" Iyi }
                catch { Yaz "  Kaldırılamadı: $s" Uyari }
            }
        }
    } else {
        Yaz 'Kaldırmak için: .\yazici-kuyruk-sifirla.ps1 -SurucuTemizle' Bilgi
    }
} else {
    Yaz 'Kullanılmayan sürücü yok.' Iyi
}

# son 24 saatteki biriktirici hataları
$hatalar = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-PrintService/Admin'; StartTime = (Get-Date).AddDays(-1)
} -ErrorAction SilentlyContinue

if ($hatalar) {
    Yaz "Son 24 saatte $($hatalar.Count) yazdırma hatası kaydı var. En sıkları:" Uyari
    $hatalar | Group-Object Id | Sort-Object Count -Descending | Select-Object -First 3 |
        ForEach-Object { Yaz "  Olay $($_.Name): $($_.Count) kez" Uyari }
    Yaz 'Aynı olay tekrarlıyorsa sorun kuyrukta değil, sürücüde veya yazıcıdadır.' Bilgi
} else {
    Yaz 'Son 24 saatte yazdırma hatası kaydı yok.' Iyi
}
