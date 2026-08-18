#!/usr/bin/env bash
# bilgince.com — Ansible envanter doğrulaması. Yalnızca ping; görev çalıştırmaz.
set -uo pipefail
ENVANTER="${1:-inventory}"

baslik() { printf '\n\033[1;36m== %s\033[0m\n' "$1"; }

command -v ansible >/dev/null || { echo "ansible bulunamadı"; exit 1; }
[ -e "$ENVANTER" ] || { echo "envanter yok: $ENVANTER"; exit 1; }

baslik "Gruplar ve makine sayıları"
ansible-inventory -i "$ENVANTER" --list 2>/dev/null |
  python3 -c "
import json,sys
d=json.load(sys.stdin)
for g,v in sorted(d.items()):
    if g in ('_meta','all'): continue
    h=v.get('hosts',[])
    if h: print(f'{g:30} {len(h)}')
" 2>/dev/null || ansible-inventory -i "$ENVANTER" --graph

baslik "Aynı anda birden çok grupta olan makineler"
ansible-inventory -i "$ENVANTER" --list 2>/dev/null |
  python3 -c "
import json,sys,collections
d=json.load(sys.stdin)
s=collections.Counter()
for g,v in d.items():
    if g in ('_meta','all'): continue
    for h in v.get('hosts',[]): s[h]+=1
for h,n in s.most_common():
    if n>1: print(f'{h:35} {n} grup')
" 2>/dev/null || true

baslik "Erişilebilirlik (ping modülü)"
ansible all -i "$ENVANTER" -m ping -o 2>&1 |
  awk '{ if ($0 ~ /SUCCESS/) ok++; else { print; fail++ } }
       END { printf "\nulasilan: %d  ulasilamayan: %d\n", ok, fail }'

baslik "Sözdizimi denetimi"
if [ -f site.yml ]; then
  ansible-playbook -i "$ENVANTER" site.yml --syntax-check && echo "site.yml sözdizimi geçerli"
else
  echo "site.yml yok, atlandı"
fi

printf '\n\033[1;33mUlaşılamayan makineler playbook ortasında değil, burada görülmeli.\033[0m\n'
