#!/usr/bin/env bash
# bilgince.com — Linux erişim denetimi. Salt okunur; hiçbir hesabı değiştirmez.
set -uo pipefail

baslik() { printf '\n\033[1;36m== %s\033[0m\n' "$1"; }

baslik "Kabuk sahibi hesaplar"
awk -F: '$7 !~ /(nologin|false|sync)$/ { printf "%-20s uid=%-6s kabuk=%s\n", $1, $3, $7 }' /etc/passwd

baslik "UID 0 olan hesaplar (root eşdeğeri)"
# root dışında UID 0 varsa bu ciddi bir bulgudur
awk -F: '$3 == 0 { print $1 }' /etc/passwd

baslik "sudo yetkisi olanlar"
if [ -r /etc/sudoers ]; then
  grep -vE '^\s*#|^\s*$' /etc/sudoers 2>/dev/null | grep -E 'ALL|NOPASSWD' || echo "kayıt yok"
  for d in /etc/sudoers.d/*; do
    [ -r "$d" ] || continue
    echo "--- $d"
    grep -vE '^\s*#|^\s*$' "$d"
  done
else
  echo "sudoers okunamadı (root gerekir)"
fi

baslik "Parolasız sudo (NOPASSWD)"
grep -rhE 'NOPASSWD' /etc/sudoers /etc/sudoers.d/ 2>/dev/null || echo "yok"

baslik "Yetkili gruplar"
for g in sudo wheel adm docker; do
  uyeler=$(getent group "$g" 2>/dev/null | cut -d: -f4)
  [ -n "${uyeler:-}" ] && printf '%-8s %s\n' "$g" "$uyeler"
done
echo "(docker grubu pratikte root yetkisidir)"

baslik "SSH anahtarları"
for ev in /home/* /root; do
  [ -d "$ev/.ssh" ] || continue
  ad=$(basename "$ev")
  n=$(grep -cvE '^\s*$|^#' "$ev/.ssh/authorized_keys" 2>/dev/null || echo 0)
  [ "$n" -gt 0 ] && printf '%-20s %s anahtar\n' "$ad" "$n"
done

baslik "SSH sunucu ayarları"
if [ -r /etc/ssh/sshd_config ]; then
  grep -iE '^\s*(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|Port)' /etc/ssh/sshd_config \
    || echo "hepsi varsayılan"
else
  echo "sshd_config okunamadı"
fi

baslik "Parolası hiç değişmemiş ya da süresiz hesaplar"
if command -v chage >/dev/null; then
  awk -F: '$7 !~ /(nologin|false)$/ { print $1 }' /etc/passwd | while read -r k; do
    son=$(chage -l "$k" 2>/dev/null | awk -F: '/Last password change/ { print $2 }')
    [ -n "${son:-}" ] && printf '%-20s%s\n' "$k" "$son"
  done
else
  echo "chage yok"
fi

printf '\n\033[1;33mdocker grubu üyeliği ve NOPASSWD kayıtları root ile eşdeğerdir; ikisini de gerekçesiyle kayda geçirin.\033[0m\n'
