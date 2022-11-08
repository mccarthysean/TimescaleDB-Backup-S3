#! /bin/sh

# This file performs the backup operation. Then it uploads the file to an AWS S3 bucket with the command.

# Ignore the warning "pg_dump: NOTICE:  hypertable data are in the chunks, no data will be copied"
# See the following explanation:
# https://stackoverflow.com/questions/64478510/not-able-to-take-backup-of-hypertable-timescaledb-database-using-pg-dump-postgre


set -e
set -o pipefail

if [ "${AWS_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "You need to set the AWS_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ "${AWS_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "You need to set the AWS_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ "${AWS_DEFAULT_REGION}" = "**None**" ]; then
  echo "You need to set the AWS_DEFAULT_REGION environment variable."
  exit 1
fi

if [ "${S3_BUCKET}" = "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${S3_ENDPOINT}" == "**None**" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

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

if [ "${POSTGRES_PORT}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PORT environment variable."
  exit 1
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi


# https://docs.timescale.com/timescaledb/latest/how-to-guides/backup-and-restore/pg-dump-and-restore/
# First remove the existing folder, if there is one
# BACKUP_FOLDER=/ts_dump
# echo "Removing existing files and folders in $BACKUP_FILE folder..."
# rm -rf $BACKUP_FOLDER

BACKUP_FILE=/ts_dump.bak

echo ""
echo "Removing '$BACKUP_FILE' if it exists..."
rm -f $BACKUP_FILE

# echo "Creating ts-dump from host '${POSTGRES_HOST}' to directory $BACKUP_FOLDER..."
# ts-dump --db-URI postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/$POSTGRES_DATABASE --dump-dir $BACKUP_FOLDER
echo "whoami (should be 'root' I think...)?" $(whoami)
PGPASS_FILE=~/.pgpass
touch $PGPASS_FILE
echo "${POSTGRES_HOST}:${POSTGRES_PORT}:${POSTGRES_DATABASE}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > $PGPASS_FILE
# set the file's mode to 0600. Otherwise, it will be ignored.
chmod 600 $PGPASS_FILE

echo ""
echo "dump the database into a directory-format archive with the --file option..."
# pg_dump -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --no-password -Fc --file $BACKUP_FILE $POSTGRES_DATABASE
pg_dump -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --no-password -Fc --file $BACKUP_FILE $POSTGRES_DATABASE

# echo "tar and gzip the files in the $BACKUP_FOLDER folder..."
# tar -zcvf ts_dump.tar.gz $BACKUP_FOLDER

echo ""
echo "Uploading ts_dump.tar.gz to bucket '$S3_BUCKET'"
# cat ts_dump.tar.gz | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/ts_dump_$(date +"%Y-%m-%dT%H:%M:%SZ").tar.gz || exit 2
cat $BACKUP_FILE | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/ts_dump_$(date +"%Y-%m-%dT%H:%M:%SZ").bak || exit 2

echo ""
echo "SQL backup '$BACKUP_FILE' successfully uploaded to AWS S3 bucket '$S3_BUCKET'!"
exit 0
