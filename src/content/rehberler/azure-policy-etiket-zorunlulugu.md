---
baslik: "Azure Policy ile etiket zorunluluğu: maliyeti sahiplendirmek"
ozet: "Etiketsiz kaynak, sahipsiz maliyet demektir. Policy ile etiketi zorunlu kılmanın ve mevcut kaynakları geriye dönük düzeltmenin yolu."
konu: "azure"
etiketler: ["yonetisim", "maliyet", "policy"]
yayin: 2026-02-03
sure: 11
---

"Bu kaynak kimin?" sorusuna cevap veremiyorsanız maliyet raporu üretmenin anlamı yok. Etiket disiplini bu yüzden maliyet çalışmasının değil, yönetişimin parçasıdır.

## Önce denetleyin, sonra engelleyin

İlk günden `Deny` etkisiyle başlamak dağıtım hatlarını kırar ve size düşman kazandırır. Sıra şu olmalı: **Audit → Modify → Deny**.

```bash
# 1. aşama: yalnızca raporla
az policy assignment create \
  --name "etiket-owner-denetim" \
  --policy "871b6d14-10aa-478d-b590-94f262ecfa99" \
  --params '{ "tagName": { "value": "Owner" } }' \
  --scope "/subscriptions/<abonelik-kimligi>"
```

Bir hafta sonra **Compliance** ekranında uyumsuz kaynak sayısını görürsünüz. Bu sayı ekiple konuşmanız gereken gerçek rakamdır.

## Kaynak grubundan miras aldırmak

Her kaynağa tek tek etiket yazdırmak yerine, kaynak grubunun etiketini kaynaklara kopyalayan yerleşik `Modify` politikası çok daha az sürtünme yaratır. Bu politika bir yönetilen kimlik ister:

```bash
az policy assignment create \
  --name "etiket-miras-owner" \
  --policy "cd3aa116-8754-49c9-a813-ad46512ece54" \
  --params '{ "tagName": { "value": "Owner" } }' \
  --scope "/subscriptions/<abonelik-kimligi>" \
  --mi-system-assigned --location westeurope \
  --role Contributor --identity-scope "/subscriptions/<abonelik-kimligi>"
```

## Mevcut kaynakları düzeltmek

Politika yalnızca yeni kaynakları etkiler. Eskiler için **remediation task** çalıştırmanız gerekir:

```bash
az policy remediation create \
  --name "etiket-miras-duzeltme" \
  --policy-assignment "etiket-miras-owner" \
  --resource-group "uretim-rg"
```

## Doğrulama adımı

Düzeltme bittikten sonra etiketsiz kaynak sayısını sayın:

```kusto
Resources | where isnull(tags['Owner']) | summarize count() by subscriptionId, type
```

Sayı sıfıra inmiyorsa kalanlar büyük olasılıkla politika kapsamı dışındaki kaynak türleridir (bazı hizmetler etiket desteklemez). O listeyi belgeleyip istisna olarak kaydedin — "bilinen istisna", "unutulmuş kaynak"tan çok farklıdır.
