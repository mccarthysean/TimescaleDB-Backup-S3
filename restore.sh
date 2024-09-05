#! /bin/sh

set -e
set -o pipefail

# This file will restore a backup named "${POSTGRES_DATABASE}.bak"
# so ensure it's named appropriately, and included in the same folder.

echo ""
echo "Enter the name of the backup file previously downloaded from bucket '$S3_BUCKET' and subfolder '$S3_PREFIX': "  
read BACKUP_FILE
echo "You've entered $BACKUP_FILE. That will be used when we un-tar the file."

if [ "${POSTGRES_DATABASE}" = "**None**" ]; then
  echo ""
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo ""
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo ""
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo ""
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi

# BACKUP_FOLDER=/ts_dump

# # First remove the existing folder, if there is one
# echo ""
# echo "Removing existing $BACKUP_FOLDER directory if it exists..."
# rm -rf $BACKUP_FOLDER

# echo ""
# echo "Making new $BACKUP_FOLDER directory..."
# mkdir -p $BACKUP_FOLDER

# echo ""
# echo "Extracting to $BACKUP_FOLDER directory and its contents from $BACKUP_FILE..."
# # tar -zxvf $BACKUP_FILE -C $BACKUP_FOLDER
# # No need to add "-C $BACKUP_FOLDER" since that happens automatically
# tar -zxvf $BACKUP_FILE

# echo "Creating ts-dump from host '${POSTGRES_HOST}' to directory $BACKUP_FOLDER..."
# ts-dump --db-URI postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/$POSTGRES_DATABASE --dump-dir $BACKUP_FOLDER

echo ""
echo "whoami (should be 'root' I think...)?" $(whoami)
# PGPASS_FILE=~/.pgpass
# touch $PGPASS_FILE
# echo "${POSTGRES_HOST}:${POSTGRES_PORT}:${POSTGRES_DATABASE}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > $PGPASS_FILE
# # set the file's mode to 0600. Otherwise, it will be ignored.
# chmod 600 $PGPASS_FILE

# Set PGPASSWORD environment variable, which psql will use to connect to the database
export PGPASSWORD="${POSTGRES_PASSWORD}"

# https://docs.timescale.com/timescaledb/latest/how-to-guides/backup-and-restore/pg-dump-and-restore/
echo ""
echo "Restoring dump of database to host '${POSTGRES_HOST}' from source file $BACKUP_FILE..."
# echo ""
# echo "Please ensure the database '$POSTGRES_DATABASE' is already created, but completely empty; otherwise the following might not work..."
echo ""
echo "Creating database '$POSTGRES_DATABASE' if it doesn't already exist..."
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -tc "SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DATABASE'" | grep -q 1 || psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -c "CREATE DATABASE $POSTGRES_DATABASE"

echo ""
echo "Creating extension 'timescaledb' if it doesn't already exist..."
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DATABASE -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

echo ""
echo "Running timescaledb_pre_restore() to put the database $POSTGRES_DATABASE in the right state for restoring..."
echo "SELECT timescaledb_pre_restore();"
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DATABASE -c "SELECT timescaledb_pre_restore();"
sleep 5

echo ""
echo "Restoring database now..."
# ts-restore --db-URI postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/$POSTGRES_DATABASE --dump-dir $BACKUP_FOLDER
# WARNING: Do not use the pg_restore command with -j option. This option does not correctly restore the Timescale catalogs.
pg_restore -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -Fc -d $POSTGRES_DATABASE $BACKUP_FILE

echo ""
echo "Running timescaledb_post_restore() to return the database $POSTGRES_DATABASE to normal operations..."
echo "SELECT timescaledb_post_restore();"
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DATABASE -c "SELECT timescaledb_post_restore();"

sleep 5
echo ""
echo "SQL backup restored successfully!"
exit 0
