#! /bin/sh

# This file installs the AWS CLI Python program, and crontab,
# in the Dockerized PostgreSQL 12 container

# exit if a command fails
set -e

apk update

# Install pg_dump (already included in postgres:12-alpine official Docker image)
# apk add postgresql

# Install S3 tools
apk add python3 py3-pip
pip3 install awscli six
# apk del py3-pip

# Install go-cron
apk add curl
curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron
chmod u+x /usr/local/bin/go-cron
apk del curl

# Cleanup to reduce container size
rm -rf /var/cache/apk/*