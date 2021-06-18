#! /bin/sh

set -e
set -o pipefail

# This file will restore a backup named "${POSTGRES_DATABASE}.bak"
# so ensure it's named appropriately, and included in the same folder.

echo ""
echo "Enter the name of the backup file previously downloaded from bucket '$S3_BUCKET' and subfolder '$S3_PREFIX': "  
read backup_name
echo "You've entered $backup_name. That will be used when we un-tar the file."

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

# First remove the existing folder, if there is one
echo ""
echo "Removing existing /ts_dump directory if it exists..."
rm -rf /ts_dump

echo ""
echo "Making new /ts_dump directory..."
mkdir -p /ts_dump

echo ""
echo "Extracting to /ts_dump directory and its contents from $backup_name..."
# tar -zxvf $backup_name -C /ts_dump
# No need to add "-C /ts_dump" since that happens automatically
tar -zxvf $backup_name

echo ""
echo "Restoring dump of database to host '${POSTGRES_HOST}' from source directory /ts_dump..."
echo ""
echo "Please ensure the database '$POSTGRES_DATABASE' is already created, but completely empty; otherwise the following might not work..."
sleep 5
echo ""
ts-restore --db-URI postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/$POSTGRES_DATABASE --dump-dir /ts_dump

echo ""
echo "SQL backup restored successfully!"