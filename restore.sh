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


echo "Restoring dump of db '${POSTGRES_DATABASE}' to host '${POSTGRES_HOST}' from source file '${POSTGRES_DATABASE}.bak'..."

# Restoring data from a backup currently requires some additional procedures, which need to be run from psql
# psql [option...] [dbname [username]]
# --dbname is equivalent to specifying dbname as the first non-option argument on the command line
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --dbname $POSTGRES_DATABASE --command 'CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;'
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --dbname $POSTGRES_DATABASE --command 'SELECT timescaledb_pre_restore();'

# pg_restore [connection-option...] [option...] [filename]
# Added || true so the following line returns an error code of 0, since we need the line after this one to run regardless
pg_restore -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --dbname $POSTGRES_DATABASE $POSTGRES_RESTORE_EXTRA_OPTS ${POSTGRES_DATABASE}.bak || true

# Restoring data from a backup currently requires some additional procedures, which need to be run from psql
# psql [option...] [dbname [username]]
# --dbname is equivalent to specifying dbname as the first non-option argument on the command line
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --dbname $POSTGRES_DATABASE --command 'SELECT timescaledb_post_restore();'

echo "SQL backup restored successfully"
