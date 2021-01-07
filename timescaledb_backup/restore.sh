#! /bin/sh

set -e
set -o pipefail

# This file will restore a backup named "${PGDATABASE}.bak"
# so ensure it's named appropriately, and included in the same folder.


if [ "${PGDATABASE}" = "**None**" ]; then
  echo "You need to set the PGDATABASE environment variable."
  exit 1
fi

if [ "${PGHOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    PGHOST=$POSTGRES_PORT_5432_TCP_ADDR
    PGPORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the PGHOST environment variable."
    exit 1
  fi
fi

if [ "${PGUSER}" = "**None**" ]; then
  echo "You need to set the PGUSER environment variable."
  exit 1
fi

if [ "${PGPASSWORD}" = "**None**" ]; then
  echo "You need to set the PGPASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi


echo "Restoring dump of db '${PGDATABASE}' to host '${PGHOST}' from source file '${PGDATABASE}.bak'..."

# Restoring data from a backup currently requires some additional procedures, which need to be run from psql
# psql [option...] [dbname [username]]
# --dbname is equivalent to specifying dbname as the first non-option argument on the command line
psql -h $PGHOST -p $PGPORT -U $PGUSER --dbname $PGDATABASE --command 'CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;'
psql -h $PGHOST -p $PGPORT -U $PGUSER --dbname $PGDATABASE --command 'SELECT timescaledb_pre_restore();'

# pg_restore [connection-option...] [option...] [filename]
# Added || true so the following line returns an error code of 0, since we need the line after to run regardless
pg_restore -h $PGHOST -p $PGPORT -U $PGUSER --dbname $PGDATABASE $POSTGRES_RESTORE_EXTRA_OPTS ${PGDATABASE}.bak || true

# Restoring data from a backup currently requires some additional procedures, which need to be run from psql
# psql [option...] [dbname [username]]
# --dbname is equivalent to specifying dbname as the first non-option argument on the command line
psql -h $PGHOST -p $PGPORT -U $PGUSER --dbname $PGDATABASE --command 'SELECT timescaledb_post_restore();'

echo "SQL backup restored successfully"
