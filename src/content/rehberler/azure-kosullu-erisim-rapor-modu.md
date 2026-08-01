---
baslik: "Koşullu erişimi rapor modundan yayına geçirmek"
ozet: "Rapor modu bir hafta çalıştırılmadan açılan her politika, birilerini dışarıda bırakır. Verinin nasıl okunacağı ve yayım sırası."
konu: "azure"
etiketler: ["entra-id", "kosullu-erisim", "kimlik"]
yayin: 2026-07-21
sure: 10
seri: "Entra ID'ye geçiş günlüğü"
seriSira: 3
---

Koşullu erişim politikası yazmak on dakika sürer; onu kimseyi kilitlemeden açmak iki hafta. Bu yazı ikinci kısmı anlatıyor.

## Rapor modunun okunması

Politikayı `Report-only` durumunda bir hafta bırakın, sonra oturum açma günlüklerinde politikanın **sonucunu** ölçün. Portal'daki filtre yerine sorgu daha hızlıdır:

```kusto
SigninLogs
| where TimeGenerated > ago(7d)
| mv-expand ca = ConditionalAccessPolicies
| where ca.displayName == "Tüm kullanıcılar için MFA"
| summarize Adet = count() by tostring(ca.result), AppDisplayName
| order by Adet desc
```

`reportOnlyFailure` satırları, politika açıldığında **erişimi kesilecek** olanlardır. Bu liste yayım planınızın kendisidir.

## Tipik üç sürpriz

1. **Eski kimlik doğrulama.** POP/IMAP/SMTP kullanan tarayıcılar ve çok fonksiyonlu yazıcılar modern kimlik doğrulamayı desteklemez. Ayrı bir politikayla ve ayrı bir takvimle ele alın.
2. **Hizmet hesapları.** İnteraktif olmayan hesaplar MFA yapamaz. Bunları iş yükü kimliğine taşıyın; muafiyet listesine atmayın.
3. **Break-glass hesapları.** Politikaların tamamından hariç tutulmuş olmalı ve girişleri uyarı üretmeli.

## Yayım sırası

Departman departman, günde bir. Her günün sonunda başarısız oturum açmalara bakın:

```kusto
SigninLogs
| where TimeGenerated > ago(1d) and ResultType != 0
| summarize count() by ResultDescription, UserPrincipalName
| order by count_ desc
```

## Doğrulama adımı

Politika açıldıktan sonra iki testi de yapın: normal bir kullanıcı hesabıyla gizli pencerede giriş yapın — **MFA istemi gelmeli**. Ardından break-glass hesabıyla giriş yapın — **istem gelmemeli**. İkisi doğrulanmadan yayım tamamlanmış sayılmaz.
