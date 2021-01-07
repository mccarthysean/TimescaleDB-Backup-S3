ARG VERSION
FROM postgres:${VERSION}-alpine

LABEL maintainer="Sean McCarthy <sean.mccarthy@live.ca>"

# Install the AWS CLI Python program, and go-crontab,
# in the PostgreSQL 12 Alpine Linux container
COPY install_aws_cli.sh install_aws_cli.sh
RUN sh install_aws_cli.sh

# Set some default environment variables
# We'll override these with Docker-Compose and in the .env file
ENV PGDATABASE **None**
ENV PGHOST **None**
ENV PGPORT **None**
ENV PGUSER **None**
ENV PGPASSWORD **None**
ENV POSTGRES_BACKUP_EXTRA_OPTS ''
ENV POSTGRES_RESTORE_EXTRA_OPTS ''
ENV AWS_ACCESS_KEY_ID **None**
ENV AWS_SECRET_ACCESS_KEY **None**
ENV S3_BUCKET **None**
ENV AWS_DEFAULT_REGION **None**
ENV S3_ENDPOINT **None**
ENV S3_S3V4 no
ENV SCHEDULE **None**

# Add a few more files to the container
# backup.sh actually runs the backup, and then uploads it to an AWS S3 bucket
COPY backup.sh backup.sh
# restore.sh will restore a database from a backup file,
# which has been downloaded from AWS S3 and renamed "postgres.bak"
COPY restore.sh restore.sh

# run_or_schedule_backup.sh schedules the backup with cron
COPY run_or_schedule_backup.sh run_or_schedule_backup.sh

# Schedule crontab when the container starts.
CMD ["sh", "run_or_schedule_backup.sh"]