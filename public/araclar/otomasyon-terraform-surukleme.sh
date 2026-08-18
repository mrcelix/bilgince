#!/usr/bin/env bash
# bilgince.com — Terraform sürükleme raporu. Uygulama yapmaz.
set -uo pipefail
DIZIN="${1:-.}"
cd "$DIZIN" || { echo "dizin yok: $DIZIN"; exit 1; }

baslik() { printf '\n\033[1;36m== %s\033[0m\n' "$1"; }

command -v terraform >/dev/null || { echo "terraform bulunamadı"; exit 1; }

baslik "Sürüm ve çalışma alanı"
terraform version | head -1
terraform workspace show 2>/dev/null || echo "varsayılan"

baslik "Durum dosyasındaki kaynak sayısı"
terraform state list 2>/dev/null | wc -l

baslik "Sürükleme (yalnızca okuma)"
# -detailed-exitcode: 0 fark yok, 1 hata, 2 fark var. CI'da 2'yi hata saymayın.
terraform plan -refresh-only -detailed-exitcode -no-color -input=false > /tmp/tf-plan.txt 2>&1
KOD=$?

case $KOD in
  0) echo "Sürükleme yok: gerçek altyapı kodla aynı." ;;
  2) echo "Sürükleme var:"; grep -E '^\s+[~+-]|^  # ' /tmp/tf-plan.txt | head -40 ;;
  *) echo "Plan çalışmadı:"; tail -20 /tmp/tf-plan.txt ;;
esac

baslik "Sağlayıcı sürümleri"
terraform providers 2>/dev/null | head -20

baslik "Kilit dosyası"
if [ -f .terraform.lock.hcl ]; then
  echo "var — sağlayıcı sürümleri sabitlenmiş"
else
  echo "YOK — sağlayıcı sürümü her çalıştırmada değişebilir"
fi

printf '\n\033[1;33mSürüklenen kaynağı koda yansıtın ya da elle değişikliği geri alın; ikisinden birini seçin.\033[0m\n'
