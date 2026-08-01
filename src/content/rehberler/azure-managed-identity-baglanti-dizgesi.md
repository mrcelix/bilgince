---
baslik: "Managed Identity ile bağlantı dizgelerini uygulamadan çıkarmak"
ozet: "Uygulama ayarlarında duran anahtarlar sızıntının en sık yolu. Yönetilen kimlikle parolasız erişime geçmenin adımları."
konu: "azure"
etiketler: ["kimlik", "guvenlik", "app-service"]
yayin: 2026-02-24
sure: 12
---

Bir App Service'in yapılandırmasına bakın: `DefaultEndpointsProtocol=https;AccountName=...;AccountKey=...` satırını neredeyse her zaman bulursunuz. O anahtar bir kere sızarsa döndürmek zorundasınız ve döndürdüğünüzde kimin kırılacağını bilmiyorsunuz. Yönetilen kimlik bu sorunu tamamen ortadan kaldırır.

## 1. Kimliği açın

```bash
az webapp identity assign \
  --name uygulama01 --resource-group uretim-rg
```

Çıktıdaki `principalId` değerini not edin; yetkiyi ona vereceksiniz.

## 2. Yetkiyi kaynağa verin

Anahtar yerine rol atıyorsunuz. Depolama için doğru rol `Storage Blob Data Contributor` — `Contributor` değil. Aradaki fark önemli: `Contributor` veri düzlemine erişim vermez ama yönetim düzlemine fazlasıyla verir.

```bash
az role assignment create \
  --assignee <principalId> \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<id>/resourceGroups/uretim-rg/providers/Microsoft.Storage/storageAccounts/depo01"
```

## 3. Kodda anahtarı bırakın

```csharp
// Anahtar yok; kimlik ortamdan geliyor.
var client = new BlobServiceClient(
    new Uri("https://depo01.blob.core.windows.net"),
    new DefaultAzureCredential());
```

`DefaultAzureCredential` yerelde geliştiricinin Azure CLI oturumunu, sunucuda yönetilen kimliği kullanır. Böylece geliştirme ve üretim aynı kodu çalıştırır.

## 4. Anahtar erişimini kapatın

Bu adımı atlarsanız hiçbir şey kazanmazsınız — eski anahtar hâlâ çalışıyor olur.

```bash
az storage account update \
  --name depo01 --resource-group uretim-rg \
  --allow-shared-key-access false
```

## Doğrulama adımı

Anahtar erişimini kapattıktan sonra uygulamayı yeniden başlatın ve blob okuyan bir isteği tetikleyin. Çalışıyorsa kimlik doğru kurulmuş demektir. Ardından eski anahtarla `az storage blob list --account-key ...` deneyin — **başarısız olmalı**. İkisini de görmeden işi bitmiş saymayın.
