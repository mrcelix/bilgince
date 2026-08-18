#!/usr/bin/env bash
# bilgince.com — Linux sistem özeti. Salt okunur; hiçbir şeyi değiştirmez.
set -uo pipefail

baslik() { printf '\n\033[1;36m== %s\033[0m\n' "$1"; }

baslik "Kimlik ve çalışma süresi"
hostnamectl 2>/dev/null | sed -n '1,6p' || uname -a
uptime

baslik "Bellek"
free -h

baslik "Disk (yalnızca yerel dosya sistemleri)"
df -hxtmpfs -xdevtmpfs 2>/dev/null || df -h

baslik "En çok CPU tüketen 8 süreç"
ps -eo pid,user,pcpu,pmem,comm --sort=-pcpu | head -9

baslik "En çok bellek tüketen 8 süreç"
ps -eo pid,user,rss,pmem,comm --sort=-rss | head -9

baslik "Başarısız servisler"
if command -v systemctl >/dev/null; then
  systemctl --failed --no-legend || echo "yok"
else
  echo "systemd yok"
fi

baslik "Dinleyen portlar"
if command -v ss >/dev/null; then
  ss -tulpnH 2>/dev/null | awk '{print $1, $5, $7}' | sort -u
else
  netstat -tulpn 2>/dev/null
fi

baslik "Son 20 çekirdek/servis hatası"
if command -v journalctl >/dev/null; then
  journalctl -p err -n 20 --no-pager 2>/dev/null
else
  tail -20 /var/log/messages 2>/dev/null || echo "günlük okunamadı"
fi

baslik "Yeniden başlatma gerekiyor mu?"
if [ -f /var/run/reboot-required ]; then
  echo "EVET — /var/run/reboot-required mevcut"
elif command -v needs-restarting >/dev/null; then
  needs-restarting -r || true
else
  echo "belirlenemedi"
fi

printf '\n\033[1;33mNot: RSS paylaşılan belleği çift sayar; toplam abartılı görünebilir.\033[0m\n'
