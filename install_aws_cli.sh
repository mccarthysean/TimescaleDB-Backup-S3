#! /bin/sh

# This file installs the AWS CLI Python program
# in the Dockerized PostgreSQL 12 container

# Exit if a command fails
set -e

# Install AWS command line interface for S3 uploading
apk update
apk add python3 py3-pip
pip3 install awscli six

# # Install go-cron
# apk add curl
# curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron
# chmod u+x /usr/local/bin/go-cron
# apk del curl

# Cleanup to reduce container size
rm -rf /var/cache/apk/*