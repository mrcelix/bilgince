---
baslik: "Azure Backup: geri dönüşü test etmeden yedek saymayın"
ozet: "Yedek işi yeşil görünüyor diye kurtarma çalışıyor demek değil. Aylık geri dönüş testini otomatikleştirmenin yolu."
konu: "azure"
etiketler: ["yedekleme", "sureklilik"]
yayin: 2026-05-19
sure: 10
seri: "Yedekleme doğrulama rutini"
seriSira: 3
---

Azure Backup panosunda her satırın yeşil olması, verinin geri gelebileceğini kanıtlamaz. Kanıt yalnızca geri dönüş testinden gelir.

## Dosya düzeyinde hızlı test

Tüm makineyi geri yüklemeden, kurtarma noktasını sanal bir sürücü olarak bağlayabilirsiniz. En ucuz aylık testtir:

```bash
az backup restore files mount-rp \
  --resource-group yedek-rg \
  --vault-name kasa01 \
  --container-name "IaasVMContainer;iaasvmcontainerv2;uretim-rg;vm01" \
  --item-name vm01 \
  --rp-name <kurtarma-noktasi-adi>
```

Komut size bir betik verir; makinede çalıştırdığınızda kurtarma noktası sürücü olarak bağlanır. Birkaç dosyayı açıp içeriğini doğrulayın, sonra ayırın:

```bash
az backup restore files unmount-rp --resource-group yedek-rg --vault-name kasa01 \
  --container-name "..." --item-name vm01 --rp-name <kurtarma-noktasi-adi>
```

## Tam makine testi

Çeyrekte bir, izole bir sanal ağa tam geri yükleme yapın. Kritik olan nokta: **üretim ağına asla geri yüklemeyin.** Aynı adı taşıyan iki makine domain'de çakışır ve testiniz olaya dönüşür.

## Kurtarma süresini ölçün

Test yaparken saati tutun. RTO taahhüdünüz varsa gerçek süreyle karşılaştırın. Çoğu ekip "dört saat" yazar, ölçtüğünde dokuz saat çıkar.

## Doğrulama adımı

Testten sonra üç sayıyı bir tabloya yazın: **kurtarma noktası yaşı**, **geri yükleme süresi**, **doğrulanan dosya sayısı**. Bu tablo yıl sonunda denetçinin isteyeceği tek belgedir ve sonradan üretilemez. Test yapıp yazmamak, test yapmamakla neredeyse aynı şeydir.
