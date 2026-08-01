---
baslik: "NSG akış günlükleriyle kimin kime konuştuğunu görmek"
ozet: "Güvenlik grubu kuralını daraltmadan önce gerçek trafiği ölçün. Tahminle yazılan kural ya çok geniştir ya da üretimi keser."
konu: "azure"
etiketler: ["ag", "guvenlik", "izleme"]
yayin: 2026-03-17
sure: 10
---

Bir ağ güvenlik grubunda `Allow Any Any` kuralı bulduğunuzda ilk içgüdü onu silmektir. İkinci içgüdü — doğru olanı — önce oradan ne geçtiğini ölçmektir.

## Akış günlüklerini açın

```bash
az network watcher flow-log create \
  --name nsg-akis-uretim \
  --nsg uretim-nsg \
  --resource-group uretim-rg \
  --storage-account depo01 \
  --retention 30 \
  --workspace <log-analytics-workspace-id> \
  --interval 10
```

Traffic Analytics (`--workspace` parametresi) olmadan da günlük toplanır ama ham JSON'u kendiniz ayrıştırmanız gerekir. Log Analytics'e bağlamak bir haftalık iş tasarrufu demektir.

## Gerçek trafiği sorgulayın

Bir hafta veri biriktikten sonra:

```kusto
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(7d) and FlowStatus_s == "A"
| summarize Akis = count() by SrcIP_s, DestIP_s, DestPort_d, L7Protocol_s
| order by Akis desc
| take 50
```

Bu tablo, yazacağınız kuralların taslağıdır. Listede olmayan hiçbir portu açmayın.

## Kuralı daraltırken sıra

1. Yeni dar kuralları **daha düşük öncelik numarasıyla** (yani daha yüksek öncelikle) ekleyin.
2. Geniş kuralı silmeyin — `Deny`'a çevirmeyin de. Önce **öncelik numarasını büyütün** ki dar kurallar önce değerlendirilsin.
3. Bir hafta daha izleyin. Reddedilen akış yoksa geniş kuralı kaldırın.

Bu sıra sayesinde her adım geri alınabilir kalır.

## Doğrulama adımı

Geniş kuralı kaldırdıktan sonra aynı sorguyu `FlowStatus_s == "D"` (denied) ile çalıştırın. Beklemediğiniz bir kaynak IP reddedilmişse kuralı hemen geri alın ve o akışı listeye ekleyin. Reddedilenler listesini kapanış raporuna eklemek, altı ay sonra "bu portu kim kapattı" tartışmasını bitirir.
