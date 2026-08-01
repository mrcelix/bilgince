---
baslik: "GKE'de node havuzu boyutlandırma ve otomatik ölçekleme"
ozet: "Pod'lar bekliyorsa sorun her zaman kapasite değildir. İstek (request) değerleri, havuz ayrımı ve ölçekleyicinin gerçekte ne yaptığı."
konu: "google-cloud"
etiketler: ["gke", "kubernetes", "maliyet"]
yayin: 2026-06-02
sure: 12
---

GKE'de en pahalı hata, otomatik ölçekleyiciyi açıp kaynak isteklerini boş bırakmaktır. Ölçekleyici isteklere göre karar verir; istek yoksa doğru kararı veremez.

## Önce istekleri ölçün

```bash
kubectl top pods -A --sort-by=memory | head -20
```

Gerçek kullanımı gördükten sonra `requests` değerlerini gerçeğe yakın, `limits` değerlerini biraz üstte tutun. `requests` çok yüksekse boş kapasiteye para ödersiniz; çok düşükse pod'lar sıkışır.

## Havuzları ayırın

Tek havuzda her şeyi çalıştırmak, en pahalı makine tipini tüm iş yükleri için almanız demektir.

```bash
gcloud container node-pools create toplu-is \
  --cluster=kume01 --region=europe-west3 \
  --machine-type=e2-standard-4 \
  --enable-autoscaling --min-nodes=0 --max-nodes=10 \
  --spot \
  --node-taints=is-turu=toplu:NoSchedule
```

`--min-nodes=0` ile toplu işler bitince havuz sıfıra iner. `--spot` kesintiye dayanıklı işlerde maliyeti belirgin biçimde düşürür; taint sayesinde web trafiği bu havuza düşmez.

## Ölçekleyici neden büyütmüyor?

Çoğu zaman kapasite değil, zamanlama kısıtı sorunudur: pod anti-affinity, PodDisruptionBudget veya bölge kısıtı. Cevabı olay günlüğü verir:

```bash
kubectl get events -A --field-selector reason=FailedScheduling
kubectl describe pod <pod> | sed -n '/Events/,$p'
```

## Doğrulama adımı

Ayarları değiştirdikten sonra bir yük testi çalıştırın ve iki şeyi ölçün: **yeni node'un hazır olma süresi** ve **yükten sonra havuzun ne kadar sürede küçüldüğü**. Küçülme hiç olmuyorsa genelde sebebi, yerel depolama kullanan veya PDB'si fazla katı olan bir pod'dur — ölçekleyici o node'u boşaltamaz ve siz sürekli tepe kapasiteye ödeme yaparsınız.
