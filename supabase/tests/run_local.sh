#!/usr/bin/env bash
# يشغّل الـ migrations والاختبارات على PostgreSQL مؤقت (بدون Supabase)
# الاستخدام: bash supabase/tests/run_local.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PGBIN="$(ls -d /usr/lib/postgresql/*/bin | sort -V | tail -1)"
DATA="$(mktemp -d)"
PORT=55432
trap '"$PGBIN/pg_ctl" -D "$DATA" stop -m fast >/dev/null 2>&1 || true; rm -rf "$DATA"' EXIT

"$PGBIN/initdb" -D "$DATA" -U postgres -A trust -E UTF8 >/dev/null
"$PGBIN/pg_ctl" -D "$DATA" -o "-p $PORT -k /tmp -c listen_addresses=''" -l "$DATA/log" start >/dev/null
export PGHOST=/tmp PGPORT=$PORT PGUSER=postgres PGDATABASE=postgres

# أدوار Supabase التي يعتمد عليها المخطط
psql -q -v ON_ERROR_STOP=1 -c "create role authenticated nologin; create role anon nologin; create role service_role nologin bypassrls;"

for f in "$ROOT"/supabase/migrations/*.sql; do
  echo "→ $(basename "$f")"
  psql -q -v ON_ERROR_STOP=1 -f "$f"
done
echo
for t in "$ROOT"/supabase/tests/*_test.sql; do
  echo "== $(basename "$t")"
  psql -q -v ON_ERROR_STOP=1 -f "$t" 2>&1 | sed 's/^psql:[^ ]* NOTICE:  //' | grep -v '^$'
done
