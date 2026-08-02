---
baslik: "Private Endpoint mi Service Endpoint mi? Karar tablosu"
ozet: "İkisi de PaaS hizmetini internetten çeker ama farklı şeyler yapar. Yanlış seçim ya gereksiz maliyet ya da yanlış güvenlik hissi üretir."
konu: "azure"
etiketler: ["ag", "guvenlik", "paas"]
yayin: 2026-04-28
sure: 9
---

Depolama hesabına internetten erişimi kapatmak isteyen herkes bu iki seçenekle karşılaşır. Adları benzer, davranışları değil.

## Temel fark

**Service Endpoint** trafiği Azure omurgasında tutar ama hizmet hâlâ genel IP'sini kullanır. Erişimi alt ağ bazında kısıtlarsınız. Ücretsizdir.

**Private Endpoint** hizmete sizin sanal ağınızdan **özel bir IP** verir. Genel uç nokta tamamen kapatılabilir, şirket içi ağdan VPN üzerinden erişilebilir. Saatlik ve veri işleme ücreti vardır.

## Karar tablosu

| Durum | Seçim |
| --- | --- |
| Şirket içi ağdan (VPN/ExpressRoute) erişim gerekiyor | Private Endpoint |
| Yalnızca aynı sanal ağdaki makineler erişecek | Service Endpoint yeter |
| Veri sızıntısı riski önemli (kullanıcı kendi kovasına yazabilir) | Private Endpoint |
| Maliyet baskısı yüksek, tehdit modeli düşük | Service Endpoint |
| Eşlenmiş (peered) sanal ağlardan erişim | Private Endpoint |

## Private Endpoint'te en sık hata: DNS

Özel uç nokta kurup DNS'i bağlamayı unutmak, en sık görülen hatadır. İsim hâlâ genel IP'ye çözülür, trafik özel bağlantıyı hiç kullanmaz — ve kimse fark etmez.

```bash
az network private-dns zone create \
  --resource-group uretim-rg --name "privatelink.blob.core.windows.net"

az network private-dns link vnet create \
  --resource-group uretim-rg --zone-name "privatelink.blob.core.windows.net" \
  --name depo-baglanti --virtual-network uretim-vnet --registration-enabled false
```

## Doğrulama adımı

Sanal ağdaki bir makineden isim çözümlemesini kontrol edin:

```bash
nslookup depo01.blob.core.windows.net
```

Dönen adres **10.x veya 192.168.x** gibi özel bir adres olmalı. Genel bir IP dönüyorsa DNS bağlantısı eksiktir ve özel uç noktaya para ödeyip kullanmıyorsunuz demektir.
