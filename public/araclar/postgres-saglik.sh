#!/usr/bin/env bash
# bilgince.com — PostgreSQL sağlık raporu. Salt okunur.
set -uo pipefail

baslik() { printf '\n\033[1;36m== %s\033[0m\n' "$1"; }
sor() { psql -X -q -P pager=off -c "$1"; }

command -v psql >/dev/null || { echo "psql bulunamadı"; exit 1; }

baslik "Sürüm ve çalışma süresi"
sor "SELECT version(), date_trunc('second', now() - pg_postmaster_start_time()) AS calisma_suresi;"

baslik "Veritabanı boyutları"
sor "SELECT datname, pg_size_pretty(pg_database_size(datname)) AS boyut
     FROM pg_database WHERE datistemplate = false ORDER BY pg_database_size(datname) DESC;"

baslik "Ölü satır oranı yüksek tablolar"
sor "SELECT schemaname, relname, n_live_tup, n_dead_tup,
       round(n_dead_tup*100.0/NULLIF(n_live_tup+n_dead_tup,0),1) AS olu_yuzde, last_autovacuum
     FROM pg_stat_user_tables WHERE n_dead_tup > 1000
     ORDER BY olu_yuzde DESC NULLS LAST LIMIT 15;"

baslik "Hiç kullanılmayan indeksler"
# Yazma maliyeti üretip okuma sağlamayan indeksler; silmeden önce uygulamayı doğrulayın
sor "SELECT schemaname, relname, indexrelname, pg_size_pretty(pg_relation_size(indexrelid)) AS boyut
     FROM pg_stat_user_indexes WHERE idx_scan = 0
     ORDER BY pg_relation_size(indexrelid) DESC LIMIT 15;"

baslik "Bağlantılar"
sor "SELECT state, count(*) FROM pg_stat_activity GROUP BY state ORDER BY count DESC;"
sor "SHOW max_connections;"

baslik "Bekleyen kilitler"
sor "SELECT bekleyen.pid AS bekleyen, engelleyen.pid AS engelleyen,
       left(bekleyen.query, 60) AS bekleyen_sorgu
     FROM pg_stat_activity bekleyen
     JOIN pg_stat_activity engelleyen ON engelleyen.pid = ANY(pg_blocking_pids(bekleyen.pid))
     WHERE cardinality(pg_blocking_pids(bekleyen.pid)) > 0;"

baslik "En uzun süren açık işlemler"
sor "SELECT pid, now()-xact_start AS sure, state, left(query,60) AS sorgu
     FROM pg_stat_activity WHERE xact_start IS NOT NULL
     ORDER BY xact_start LIMIT 10;"

printf '\n\033[1;33mUzun açık işlem autovacuum'"'"'u engeller: şişmenin en sık sebebi budur.\033[0m\n'
