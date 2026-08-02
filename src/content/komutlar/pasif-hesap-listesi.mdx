---
baslik: "90 gündür giriş yapmayan etkin hesaplar"
ozet: "Pasif kullanıcı hesaplarını bulup CSV'ye döker; yeni açılmış hesapları listeye almaz."
konu: "powershell"
etiketler: ["active-directory", "raporlama"]
kod: |
  $sinir = (Get-Date).AddDays(-90)
  Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly |
    Get-ADUser -Properties LastLogonDate, whenCreated, Enabled |
    Where-Object { $_.Enabled -and $_.whenCreated -lt $sinir } |
    Export-Csv '.\pasif-hesaplar.csv' -NoTypeInformation -Encoding UTF8
dikkat: "LastLogonDate 9–14 gün gecikmeyle eşitlenir; sınırı 30 günün altına indirmeyin."
ilgiliRehber: "pasif-ad-hesap-raporu"
---
