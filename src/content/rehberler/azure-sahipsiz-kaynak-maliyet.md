---
baslik: "Azure faturasını düşürmenin ilk adımı: sahipsiz kaynakları bulmak"
ozet: "Bağlı olmayan disk, boşta duran genel IP ve kullanılmayan yük dengeleyici. Fatura optimizasyonuna mimariden değil çöpten başlanır."
konu: "azure"
etiketler: ["maliyet", "yonetisim", "kql"]
yayin: 2026-01-13
sure: 9
---

Maliyet çalışmalarının çoğu yanlış yerden başlar: rezervasyon satın alma ve makine boyutu küçültme. Oysa çoğu abonelikte faturanın gözle görülür bir kısmı, hiçbir şeye bağlı olmayan kaynaklardan gelir. Bunlar kimsenin savunmadığı, silinmesi tartışma yaratmayan kalemlerdir — yani en kolay kazanç.

## Bağlı olmayan diskler

Silinen bir sanal makinenin diski varsayılan olarak silinmez. Yıllardır duran, kimsenin adını bilmediği yüzlerce gigabayt buradadır.

```bash
az disk list --query "[?diskState=='Unattached'].{Ad:name, Grup:resourceGroup, GB:diskSizeGb, Katman:sku.name}" -o table
```

## Boşta duran genel IP adresleri

Ayrılmış (static) ama hiçbir arayüze bağlı olmayan genel IP'ler saatlik ücretlendirilir.

```bash
az network public-ip list --query "[?ipConfiguration==null].{Ad:name, Grup:resourceGroup, Yontem:publicIPAllocationMethod}" -o table
```

## Hepsini tek sorguda görmek

Azure Resource Graph, abonelik sınırlarını aşarak arama yapmanızı sağlar. Portal'daki **Resource Graph Explorer** üzerinden:

```kusto
Resources
| where type =~ 'microsoft.compute/disks' and properties.diskState == 'Unattached'
    or type =~ 'microsoft.network/publicipaddresses' and isnull(properties.ipConfiguration)
| project name, type, resourceGroup, subscriptionId, tags
| order by type asc
```

## Silmeden önce

Sahipsiz görünen her kaynak gerçekten sahipsiz değildir. İki kontrol:

1. **Etiketlere bakın.** `Owner` veya `Project` etiketi varsa önce o kişiye sorun. Etiketi olmayanlar zaten yönetişim sorununun kanıtı.
2. **Anlık görüntü alın.** Diski silmeden önce anlık görüntüsü çok daha ucuza saklanır. 30 gün bekletip sonra görüntüyü de silin.

## Doğrulama adımı

Temizlikten bir fatura dönemi sonra **Cost Analysis** ekranında `Service name = Storage` ve `Service name = Virtual Network` kalemlerini önceki ay ile karşılaştırın. Fark görünmüyorsa sildikleriniz zaten ücretsiz katmandaydı — bir sonraki adım olan makine boyutlandırmaya geçin.
