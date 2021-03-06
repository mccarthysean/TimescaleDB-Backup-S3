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


# First remove the existing folder, if there is one
echo "Removing existing files and folders in /ts_dump folder..."
rm -rf /ts_dump
echo "Creating ts-dump from host '${POSTGRES_HOST}' to directory /ts_dump..."
ts-dump --db-URI postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/$POSTGRES_DATABASE --dump-dir /ts_dump

echo "tar and gzip the files in the /ts_dump folder..."
tar -zcvf ts_dump.tar.gz /ts_dump

echo "Uploading ts_dump.tar.gz to bucket '$S3_BUCKET'"
cat ts_dump.tar.gz | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/ts_dump_$(date +"%Y-%m-%dT%H:%M:%SZ").tar.gz || exit 2

echo "SQL backup ts_dump.tar.gz uploaded to AWS S3 bucket '$S3_BUCKET' successfully!"