#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_OUTPUT="${SCRIPT_DIR}/../seed/zabbix-config.dump"

: "${SOURCE_DB_HOST:?SOURCE_DB_HOST is required}"
: "${SOURCE_DB_PORT:=5432}"
: "${SOURCE_DB_NAME:=zabbix}"
: "${SOURCE_DB_USER:=zabbix}"
: "${SOURCE_DB_PASSWORD:?SOURCE_DB_PASSWORD is required}"
: "${OUTPUT_FILE:=${DEFAULT_OUTPUT}}"

command -v pg_dump >/dev/null 2>&1 || {
    echo "ERROR: pg_dump is required." >&2
    exit 1
}

mkdir -p "$(dirname -- "${OUTPUT_FILE}")"

# Runtime/observability records are intentionally excluded. Configuration
# tables (hosts, templates, items, triggers, dashboards, users, actions, etc.)
# remain in the dump.
EXCLUDED_TABLES=(
    'history*'
    'trends*'
    'events'
    'event_*'
    'problem*'
    'acknowledges'
    'alerts'
    'auditlog*'
    'escalations'
    'sessions'
    'housekeeper'
    'task*'
    'service_alarms'
    'service_problem'
    'autoreg_host'
    'dhosts'
    'dservices'
    'proxy_history'
    'proxy_dhistory'
    'item_rtdata'
    'host_rtdata'
    'proxy_rtdata'
    'trigger_queue'
    'lastvalue'
    'ha_node'
    'changelog'
)

PG_DUMP_ARGS=(
    --host="${SOURCE_DB_HOST}"
    --port="${SOURCE_DB_PORT}"
    --username="${SOURCE_DB_USER}"
    --dbname="${SOURCE_DB_NAME}"
    --schema=public
    --data-only
    --format=custom
    --compress=9
    --no-owner
    --no-privileges
    --disable-triggers
)

for table_pattern in "${EXCLUDED_TABLES[@]}"; do
    PG_DUMP_ARGS+=("--exclude-table-data=public.${table_pattern}")
done

echo "Creating Zabbix configuration snapshot..."
echo "Source: ${SOURCE_DB_HOST}:${SOURCE_DB_PORT}/${SOURCE_DB_NAME}"
echo "Output: ${OUTPUT_FILE}"

export PGPASSWORD="${SOURCE_DB_PASSWORD}"
pg_dump "${PG_DUMP_ARGS[@]}" --file="${OUTPUT_FILE}"

pg_restore --list "${OUTPUT_FILE}" >/dev/null

echo "Configuration snapshot created successfully."
du -h "${OUTPUT_FILE}"
echo
echo "WARNING: The dump may contain password hashes, API tokens, macros,"
echo "         webhook credentials, and other secrets. Store it securely."
