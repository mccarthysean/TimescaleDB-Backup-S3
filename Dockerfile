ARG VERSION
# pg_dump and pg_restore come from this base image,
# based on the TimescaleDB version one wants
FROM postgres:${VERSION}-alpine

# Copy the Golang binaries from this official image,
# rather than installing manually
COPY --from=golang:rc-alpine /usr/local/go/ /usr/local/go/

LABEL maintainer="Sean McCarthy <sean.mccarthy@live.ca>"

RUN apk update && \
    # Install Python3 and pip to install the AWS CLI for AWS S3 access
    apk add --no-cache python3 py3-pip nano && \
    # Install AWS command line interface for S3 uploading
    pip3 install awscli six && \
    # Cleanup to reduce container size
    rm -rf /var/cache/apk/*

# Configure Go
ENV GOROOT /usr/local/go
ENV GOPATH /go
ENV PATH /usr/local/go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

# If the above build process doesn't seem to get the right version, download the Linux binaries instead, manually
RUN cd /usr/local/go/bin && \
    wget https://github.com/timescale/timescaledb-backup/releases/download/0.1.1/ts-dump_0.1.1_Linux_x86_64 && \
    wget https://github.com/timescale/timescaledb-backup/releases/download/0.1.1/ts-restore_0.1.1_Linux_x86_64 && \
    # Check the checksums for the downloaded binaries
    wget https://github.com/timescale/timescaledb-backup/releases/download/0.1.1/checksums.txt && \
    cat checksums.txt && \
    sha256sum ts-dump_0.1.1_Linux_x86_64 && \
    sha256sum ts-restore_0.1.1_Linux_x86_64 && \
    # Rename the downloaded binaries to be the default binaries with generic names
    mv ts-dump_0.1.1_Linux_x86_64 ts-dump && \
    mv ts-restore_0.1.1_Linux_x86_64 ts-restore && \
    # Make the downloaded binaries executable
    chmod +x ts-dump ts-restore

# Set some default environment variables
# We'll override these with Docker-Compose and in the .env file
ENV POSTGRES_DATABASE **None**
ENV POSTGRES_HOST **None**
ENV POSTGRES_PORT **None**
ENV POSTGRES_USER **None**
ENV POSTGRES_PASSWORD **None**
ENV AWS_ACCESS_KEY_ID **None**
ENV AWS_SECRET_ACCESS_KEY **None**
ENV S3_BUCKET **None**
ENV AWS_DEFAULT_REGION **None**
ENV S3_ENDPOINT **None**
ENV S3_S3V4 no
ENV SCHEDULE **None**
ENV EDITOR nano

# Add a few more files to the container
# backup.sh actually runs the backup, and then uploads it to an AWS S3 bucket
COPY backup.sh backup.sh
# download_backup_from_AWS_S3.sh will download a file from AWS S3
COPY download_backup_from_AWS_S3.sh download_backup_from_AWS_S3.sh
# restore.sh will restore a database from a backup file,
# which has been downloaded from AWS S3 and renamed "postgres.bak"
COPY restore.sh restore.sh

# run_or_schedule_backup.sh schedules the backup with cron
COPY run_or_schedule_backup.sh run_or_schedule_backup.sh

RUN chmod +x run_or_schedule_backup.sh && \
    chmod +x backup.sh && \
    chmod +x download_backup_from_AWS_S3.sh && \
    chmod +x restore.sh

# Schedule crontab when the container starts.
CMD ["sh", "run_or_schedule_backup.sh"]