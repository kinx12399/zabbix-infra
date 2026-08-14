#!/usr/bin/env bash

set -Eeuo pipefail

: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:=5432}"

: "${POSTGRES_DB:=zabbix}"
: "${POSTGRES_USER:=zabbix}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"

: "${POSTGRES_ADMIN_USER:=postgres}"
: "${POSTGRES_ADMIN_PASSWORD:?POSTGRES_ADMIN_PASSWORD is required}"

export PGPASSWORD="${POSTGRES_ADMIN_PASSWORD}"

echo "======================================================"
echo " Zabbix PostgreSQL + TimescaleDB preparation"
echo "======================================================"

echo "[1/4] Waiting for PostgreSQL primary..."

until pg_isready \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${POSTGRES_ADMIN_USER}" >/dev/null 2>&1
do
    echo "PostgreSQL is not ready yet..."
    sleep 3
done

echo "PostgreSQL is available."

echo "[2/4] Preparing Zabbix PostgreSQL role..."

USER_EXISTS="$(
    psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${POSTGRES_ADMIN_USER}" \
        -d postgres \
        -tAc "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}'"
)"

if [[ "${USER_EXISTS}" != "1" ]]; then

    echo "Creating PostgreSQL role: ${POSTGRES_USER}"

    psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${POSTGRES_ADMIN_USER}" \
        -d postgres \
        -v ON_ERROR_STOP=1 \
        --set=db_user="${POSTGRES_USER}" \
        --set=db_password="${POSTGRES_PASSWORD}" <<'SQL'
SELECT format(
    'CREATE ROLE %I LOGIN PASSWORD %L',
    :'db_user',
    :'db_password'
)\gexec
SQL

else

    echo "PostgreSQL role already exists."

fi


echo "[3/4] Preparing Zabbix database..."

DB_EXISTS="$(
    psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${POSTGRES_ADMIN_USER}" \
        -d postgres \
        -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'"
)"

if [[ "${DB_EXISTS}" != "1" ]]; then

    echo "Creating database: ${POSTGRES_DB}"

    createdb \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${POSTGRES_ADMIN_USER}" \
        --owner="${POSTGRES_USER}" \
        --encoding=UTF8 \
        "${POSTGRES_DB}"

else

    echo "Database already exists."

fi


echo "[4/4] Enabling TimescaleDB extension..."

psql \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${POSTGRES_ADMIN_USER}" \
    -d "${POSTGRES_DB}" \
    -v ON_ERROR_STOP=1 \
    -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"


echo
echo "======================================================"
echo " Database preparation completed."
echo "======================================================"