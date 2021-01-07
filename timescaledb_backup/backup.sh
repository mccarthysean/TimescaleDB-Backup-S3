#! /bin/sh

# This file performs the backup operation with the command:
# pg_dump -h $PGHOST -p $PGPORT -U $PGUSER $POSTGRES_BACKUP_EXTRA_OPTS --file ${PGDATABASE}.bak --dbname $PGDATABASE

# Then it uploads the ${PGDATABASE}.bak file to and AWS S3 bucket with the command:
# cat ${PGDATABASE}.bak | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/${PGDATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").bak || exit 2

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

if [ "${PGPORT}" = "**None**" ]; then
  echo "You need to set the PGPORT environment variable."
  exit 1
fi

if [ "${PGUSER}" = "**None**" ]; then
  echo "You need to set the PGUSER environment variable."
  exit 1
fi

if [ "${PGPASSWORD}" = "**None**" ]; then
  echo "You need to set the PGPASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi


echo "Creating dump of db '${PGDATABASE}' from host '${PGHOST}' to file '${PGDATABASE}.bak'..."

# pg_dump [connection-option...] [option...] [dbname]
# --dbname is equivalent to specifying dbname as the first non-option argument on the command line
# Piping it to gzip is not significantly better than just using --format custom, which is already compressed
# (e.g. adding gzip shrinks it from 505 MB to 500 MB)
# pg_dump -h $PGHOST -p $PGPORT -U $PGUSER $POSTGRES_BACKUP_EXTRA_OPTS --dbname $PGDATABASE | gzip > ${PGDATABASE}.gz
pg_dump -h $PGHOST -p $PGPORT -U $PGUSER $POSTGRES_BACKUP_EXTRA_OPTS --dbname $PGDATABASE --file ${PGDATABASE}.bak

echo "Uploading dump to bucket '$S3_BUCKET'"

# cat dump.sql.gz | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/${PGDATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz || exit 2
# cat ${PGDATABASE}.sql | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/${PGDATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql || exit 2
cat ${PGDATABASE}.bak | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/${PGDATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").bak || exit 2

echo "SQL backup uploaded successfully"
