#!/usr/bin/env bash
# bilgince.com — Linux disk analizi. Salt okunur.
set -uo pipefail
HEDEF="${1:-/}"

baslik() { printf '\n\033[1;36m== %s\033[0m\n' "$1"; }

baslik "Doluluk oranı yüksek bölümler"
df -hP | awk 'NR==1 || (int($5) >= 80)'

baslik "Inode doluluğu"
# Disk boş görünüp yazma hatası alıyorsanız sebep genelde inode tükenmesidir
df -iP | awk 'NR==1 || (int($5) >= 80)'

baslik "$HEDEF altındaki en büyük 15 dizin"
du -xh --max-depth=3 "$HEDEF" 2>/dev/null | sort -rh | head -15

baslik "En büyük 15 dosya"
find "$HEDEF" -xdev -type f -printf '%s\t%p\n' 2>/dev/null |
  sort -rn | head -15 |
  awk '{ printf "%.1f MB\t%s\n", $1/1048576, $2 }'

baslik "Silinmiş ama açık tutulan dosyalar"
if command -v lsof >/dev/null; then
  lsof +L1 2>/dev/null | awk 'NR==1 || $7 > 104857600' | head -15
  echo "(süreç yeniden başlatılınca bu alan geri gelir)"
else
  echo "lsof yok — kurulu değilse bu adım atlanır"
fi

baslik "Günlük dizini"
du -sh /var/log 2>/dev/null
journalctl --disk-usage 2>/dev/null || true
