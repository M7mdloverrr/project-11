#!/usr/bin/env bash
# Applies all migrations to a throwaway Postgres 16 container (with a small
# Supabase auth stub) and runs the RLS/RPC behaviour tests.
set -euo pipefail
cd "$(dirname "$0")/.."
name=deutschlearn-sqltest
docker rm -f "$name" >/dev/null 2>&1 || true
docker run -d --name "$name" -e POSTGRES_PASSWORD=test postgres:16 >/dev/null
trap 'docker rm -f "$name" >/dev/null' EXIT
until docker exec "$name" pg_isready -U postgres >/dev/null 2>&1; do sleep 1; done
sleep 1
run() { docker exec -i "$name" psql -q -v ON_ERROR_STOP=1 -U postgres "$@"; }
run < tests/supabase_stub.sql
for f in migrations/*.sql; do echo "applying $f"; run < "$f"; done
run -t < tests/rls_test.sql | grep -v "^\s*$" || exit 1
