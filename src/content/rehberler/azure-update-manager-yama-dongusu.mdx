---
baslik: "Azure Update Manager ile yama döngüsünü kurmak"
ozet: "WSUS'suz, ajan derdi olmadan zamanlanmış yama. Bakım penceresi, yeniden başlatma politikası ve raporlama."
konu: "azure"
etiketler: ["yama", "operasyon", "windows-server"]
yayin: 2026-06-30
sure: 11
---

Azure Update Manager, Automation hesabı ve Log Analytics bağımlılığı olmadan çalışır. Şirket içi sunucuları da Arc üzerinden aynı döngüye alabilirsiniz — asıl kazanç budur.

## Bakım yapılandırması

Yamayı makineye değil, **bakım yapılandırmasına** bağlarsınız; makineler ona katılır.

```bash
az maintenance configuration create \
  --resource-group yonetim-rg \
  --resource-name "yama-pazar-gece" \
  --maintenance-scope InGuestPatch \
  --location westeurope \
  --start-date-time "2026-07-05 02:00" \
  --duration "03:30" \
  --recur-every "1Month Second Sunday" \
  --reboot-setting IfRequired \
  --windows-parameters-classifications-to-include Critical Security
```

Süreyi (`--duration`) gerçekçi tutun. Üç buçuk saat, on sunucu için rahat; yüz sunucu için değil. Pencere yetmezse kalan makineler bir sonraki aya kalır ve kimse fark etmez.

## Dinamik kapsam

Makineleri tek tek eklemek yerine etikete göre kapsayın. Yeni kurulan sunucu doğru etiketi taşıyorsa döngüye kendiliğinden girer:

```bash
az maintenance assignment create-or-update-subscription \
  --resource-group yonetim-rg \
  --maintenance-configuration-id "<yapilandirma-kimligi>" \
  --filter-tags '{"Yama":["Pazar"]}'
```

## Yeniden başlatma politikası

`IfRequired` çoğu durumda doğrudur. `Never` seçerseniz yamalar kurulur ama etkin olmaz — pano yeşil görünür, sunucu korumasız kalır. Bu, bu ürünle yapılan en sessiz hatadır.

## Doğrulama adımı

Pencereden sonra uyumluluğu sorgulayın:

```kusto
patchassessmentresources
| where type =~ "microsoft.compute/virtualmachines/patchassessmentresults/softwarepatches"
| where properties.patchName != "" and properties.classifications has "Security"
| summarize EksikYama = count() by tostring(split(id, "/")[8])
| order by EksikYama desc
```

Aynı makine üst üste iki ay listede kalıyorsa yama başarısız oluyor demektir; pencere süresine değil, o makinenin günlüklerine bakın.
