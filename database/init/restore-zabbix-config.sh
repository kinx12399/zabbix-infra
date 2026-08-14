#!/usr/bin/env bash

set -Eeuo pipefail

: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:=5432}"
: "${POSTGRES_DB:=zabbix}"
: "${POSTGRES_USER:=zabbix}"
: "${POSTGRES_ADMIN_USER:=postgres}"
: "${POSTGRES_ADMIN_PASSWORD:?POSTGRES_ADMIN_PASSWORD is required}"
: "${CONFIG_SEED_FILE:=/opt/zabbix-seed/zabbix-config.dump}"

export PGPASSWORD="${POSTGRES_ADMIN_PASSWORD}"

psql_admin() {
    psql \
        --host="${DB_HOST}" \
        --port="${DB_PORT}" \
        --username="${POSTGRES_ADMIN_USER}" \
        --dbname="${POSTGRES_DB}" \
        --no-psqlrc \
        "$@"
}

echo "======================================================"
echo " Zabbix configuration bootstrap"
echo "======================================================"

until pg_isready \
    --host="${DB_HOST}" \
    --port="${DB_PORT}" \
    --username="${POSTGRES_ADMIN_USER}" >/dev/null 2>&1
do
    echo "PostgreSQL is not ready yet..."
    sleep 3
done

until [[ "$(psql_admin -tAc "SELECT to_regclass('public.dbversion') IS NOT NULL" 2>/dev/null || true)" == "t" ]]
do
    echo "Zabbix schema is not ready yet..."
    sleep 3
done

psql_admin -v ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE IF NOT EXISTS public.infra_bootstrap (
    id smallint PRIMARY KEY CHECK (id = 1),
    seed_checksum text NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now()
);
SQL

psql_admin -v ON_ERROR_STOP=1 --set=zabbix_user="${POSTGRES_USER}" <<'SQL'
SELECT format('GRANT SELECT ON public.infra_bootstrap TO %I', :'zabbix_user')
\gexec
SQL

if [[ ! -s "${CONFIG_SEED_FILE}" ]]; then
    echo "No configuration snapshot found; keeping the default Zabbix configuration."
    psql_admin -v ON_ERROR_STOP=1 <<'SQL'
INSERT INTO public.infra_bootstrap (id, seed_checksum)
VALUES (1, 'none')
ON CONFLICT (id) DO NOTHING;
SQL
    exit 0
fi

command -v sha256sum >/dev/null 2>&1 || {
    echo "ERROR: sha256sum is required." >&2
    exit 1
}

command -v pg_restore >/dev/null 2>&1 || {
    echo "ERROR: pg_restore is required." >&2
    exit 1
}

# Validate the archive before touching the initialized database.
pg_restore --list "${CONFIG_SEED_FILE}" >/dev/null

SEED_CHECKSUM="$(sha256sum "${CONFIG_SEED_FILE}" | awk '{print $1}')"
CURRENT_CHECKSUM="$(psql_admin -tAc "SELECT seed_checksum FROM public.infra_bootstrap WHERE id = 1" | xargs)"

if [[ "${CURRENT_CHECKSUM}" == "${SEED_CHECKSUM}" ]]; then
    echo "Configuration snapshot is already applied (${SEED_CHECKSUM})."
    exit 0
fi

if [[ -n "${CURRENT_CHECKSUM}" ]]; then
    echo "ERROR: This database was already bootstrapped with a different snapshot." >&2
    echo "       Refusing to erase a running database automatically." >&2
    echo "       Recreate the database volumes before applying a changed snapshot." >&2
    exit 1
fi

echo "Applying configuration snapshot: ${CONFIG_SEED_FILE}"
echo "Checksum: ${SEED_CHECKSUM}"

# The target schema and TimescaleDB hypertables were created by the official
# Zabbix initializer. Clear their rows, then restore only public schema data.
psql_admin -v ON_ERROR_STOP=1 <<'SQL'
SELECT format(
    'TRUNCATE TABLE %s CASCADE;',
    string_agg(format('%I.%I', schemaname, tablename), ', ')
)
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename <> 'infra_bootstrap'
\gexec

TRUNCATE TABLE public.infra_bootstrap;
SQL

pg_restore \
    --host="${DB_HOST}" \
    --port="${DB_PORT}" \
    --username="${POSTGRES_ADMIN_USER}" \
    --dbname="${POSTGRES_DB}" \
    --data-only \
    --no-owner \
    --no-privileges \
    --disable-triggers \
    --single-transaction \
    --exit-on-error \
    "${CONFIG_SEED_FILE}"

# These tables contain runtime values, so their source rows are intentionally
# not exported. Zabbix still requires one default row for every corresponding
# configuration object before it can update availability and proxy status.
psql_admin -v ON_ERROR_STOP=1 <<'SQL'
INSERT INTO public.proxy_rtdata (proxyid)
SELECT proxyid FROM public.proxy
ON CONFLICT (proxyid) DO NOTHING;

INSERT INTO public.host_rtdata (hostid)
SELECT hostid FROM public.hosts
ON CONFLICT (hostid) DO NOTHING;

INSERT INTO public.item_rtdata (itemid)
SELECT itemid FROM public.items
ON CONFLICT (itemid) DO NOTHING;
SQL

psql_admin -v ON_ERROR_STOP=1 \
    --set=seed_checksum="${SEED_CHECKSUM}" <<'SQL'
INSERT INTO public.infra_bootstrap (id, seed_checksum)
VALUES (1, :'seed_checksum');
SQL

echo "Configuration snapshot restored successfully."
echo "======================================================"
