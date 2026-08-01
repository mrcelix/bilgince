---
baslik: "Servis hesabı anahtarlarını Workload Identity ile kaldırmak"
ozet: "İndirilen JSON anahtarlar süresizdir ve nerede olduklarını kimse bilmez. GKE ve CI/CD için anahtarsız kimliğe geçiş."
konu: "google-cloud"
etiketler: ["iam", "guvenlik", "gke", "cicd"]
yayin: 2026-03-10
sure: 12
---

Servis hesabı anahtarı bir dosyadır; kopyalanır, laptopta kalır, kod deposuna düşer ve süresi hiç dolmaz. GCP'de bunların çoğu tamamen ortadan kaldırılabilir.

## Önce envanter

```bash
for p in $(gcloud projects list --format="value(projectId)"); do
  for sa in $(gcloud iam service-accounts list --project="$p" --format="value(email)"); do
    n=$(gcloud iam service-accounts keys list --iam-account="$sa" --project="$p" \
        --managed-by=user --format="value(name)" | wc -l)
    [ "$n" -gt 0 ] && echo "$p | $sa | $n anahtar"
  done
done
```

`--managed-by=user` önemlidir: Google'ın yönettiği anahtarlar sorun değil, indirilen anahtarlar sorundur.

## GKE için Workload Identity

Pod, Kubernetes servis hesabı üzerinden Google servis hesabına dönüşür; dosya taşımaz.

```bash
gcloud container clusters update kume01 --region=europe-west3 \
  --workload-pool=sirket-uretim-web.svc.id.goog

gcloud iam service-accounts add-iam-policy-binding \
  uygulama-sa@sirket-uretim-web.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:sirket-uretim-web.svc.id.goog[uretim/uygulama-ksa]"
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: uygulama-ksa
  namespace: uretim
  annotations:
    iam.gke.io/gcp-service-account: uygulama-sa@sirket-uretim-web.iam.gserviceaccount.com
```

## CI/CD için Workload Identity Federation

GitHub Actions'a JSON anahtar koymak yerine, GitHub'ın OIDC belirtecine güvenirsiniz. Havuz koşulunu **depoya göre** daraltmayı unutmayın; aksi hâlde başka bir depo da kimliğinizi alabilir.

## Anahtar oluşturmayı yasaklayın

```bash
gcloud resource-manager org-policies enable-enforce \
  constraints/iam.disableServiceAccountKeyCreation --organization=123456789012
```

Bu kısıtlamayı açmadan yaptığınız temizlik, ertesi hafta yenisi oluşturulduğu için boşa gider.

## Doğrulama adımı

Geçişten sonra pod içinde kimliği sorgulayın:

```bash
kubectl exec -it <pod> -n uretim -- \
  curl -s -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email"
```

Dönen adres beklediğiniz servis hesabı olmalı. Varsayılan Compute servis hesabı dönüyorsa bağlama tutmamıştır ve pod hâlâ fazla yetkiyle çalışıyordur.
