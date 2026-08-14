#!/usr/bin/env bash

set -Eeuo pipefail

: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:=5432}"

: "${POSTGRES_DB:=zabbix}"
: "${POSTGRES_USER:=zabbix}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"

export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "======================================================"
echo " Zabbix TimescaleDB initialization"
echo "======================================================"

echo "[1/4] Waiting for Zabbix database schema..."

until [[ "$(
    psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        -tAc "SELECT to_regclass('public.dbversion') IS NOT NULL" \
        2>/dev/null || true
)" == "t" ]]
do
    echo "Zabbix schema is not ready yet..."
    sleep 3
done

echo "Zabbix schema is available."


echo "[2/4] Checking existing TimescaleDB hypertables..."

HYPERTABLE_EXISTS="$(
    psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        -tAc "
            SELECT 1
            FROM timescaledb_information.hypertables
            WHERE hypertable_name='history'
            LIMIT 1;
        "
)"

if [[ "${HYPERTABLE_EXISTS}" == "1" ]]; then

    echo "Zabbix TimescaleDB hypertables already exist."

else

    echo "[3/4] Locating Zabbix TimescaleDB schema.sql..."

    SCHEMA_FILE="$(
        find \
            /usr/share \
            /usr/local/share \
            /opt \
            -type f \
            -path '*postgresql/timescaledb/schema.sql' \
            2>/dev/null \
            | head -n 1
    )"

    if [[ -z "${SCHEMA_FILE}" ]]; then
        echo "ERROR: Zabbix TimescaleDB schema.sql was not found."
        exit 1
    fi

    echo "Using:"
    echo "${SCHEMA_FILE}"

    echo "Applying Zabbix TimescaleDB schema..."

    psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        -v ON_ERROR_STOP=1 \
        -f "${SCHEMA_FILE}"

fi


echo "[4/4] Verifying TimescaleDB hypertables..."

psql \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${POSTGRES_USER}" \
    -d "${POSTGRES_DB}" \
    -c "
        SELECT hypertable_name
        FROM timescaledb_information.hypertables
        ORDER BY hypertable_name;
    "


echo
echo "======================================================"
echo " Zabbix TimescaleDB initialization completed."
echo "======================================================"