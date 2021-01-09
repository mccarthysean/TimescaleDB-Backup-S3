#! /bin/sh

set -e
set -o pipefail

# This file will restore a backup named "${POSTGRES_DATABASE}.bak"
# so ensure it's named appropriately, and included in the same folder.


if [ "${POSTGRES_DATABASE}" = "**None**" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi

echo "Extracting /ts_dump directory and its contents from ts_dump.tar.gz..."
# First remove the existing folder, if there is one
rm -rf /ts_dump
tar -zxvf ts_dump.tar.gz

echo "Restoring dump of database to host '${POSTGRES_HOST}' from source file 'ts_dump.tar.gz'..."
ts-restore --db-URI postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/$POSTGRES_DATABASE --dump-dir /ts_dump || true

# Restoring data from a backup currently requires some additional procedures, which need to be run from psql
# psql [option...] [dbname [username]]
# --dbname is equivalent to specifying dbname as the first non-option argument on the command line
# psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --dbname $POSTGRES_DATABASE --command 'SELECT timescaledb_post_restore();'

echo "SQL backup restored successfully!"
