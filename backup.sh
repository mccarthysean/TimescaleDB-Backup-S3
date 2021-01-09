#! /bin/sh

# This file performs the backup operation with the command:
# pg_dump -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_BACKUP_EXTRA_OPTS --file ${POSTGRES_DATABASE}.bak --dbname $POSTGRES_DATABASE

# Then it uploads the ${POSTGRES_DATABASE}.bak file to and AWS S3 bucket with the command:
# cat ${POSTGRES_DATABASE}.bak | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/${POSTGRES_DATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").bak || exit 2

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


echo "Creating dump of db '${POSTGRES_DATABASE}' from host '${POSTGRES_HOST}' to file '${POSTGRES_DATABASE}.bak'..."

# pg_dump [connection-option...] [option...] [dbname]
# --dbname is equivalent to specifying dbname as the first non-option argument on the command line
# Piping it to gzip is not significantly better than just using --format custom, which is already compressed
# (e.g. adding gzip shrinks it from 505 MB to 500 MB)
# pg_dump -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_BACKUP_EXTRA_OPTS --dbname $POSTGRES_DATABASE | gzip > ${POSTGRES_DATABASE}.gz
pg_dump -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_BACKUP_EXTRA_OPTS --dbname $POSTGRES_DATABASE --file ${POSTGRES_DATABASE}.bak

echo "Uploading dump to bucket '$S3_BUCKET'"

# cat dump.sql.gz | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/${POSTGRES_DATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz || exit 2
# cat ${POSTGRES_DATABASE}.sql | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/${POSTGRES_DATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql || exit 2
cat ${POSTGRES_DATABASE}.bak | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/${POSTGRES_DATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").bak || exit 2

echo "SQL backup uploaded successfully"
