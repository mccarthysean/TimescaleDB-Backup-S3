#!/bin/bash

# This file builds the images and pushes them to Docker Hub.
# Set the TAG_VERSION environment variable below

TAG_VERSION=1.0.3

PS3='Enter 1-2 for PostgreSQL/TimescaleDB version to build and push to Docker Hub: '
options=(
    "PostgreSQL/TimescaleDB Version 11"
    "PostgreSQL/TimescaleDB Version 12"
)
select opt in "${options[@]}"
do
    case $opt in
        "PostgreSQL/TimescaleDB Version 11")
            export VERSION=11
            break;;
        "PostgreSQL/TimescaleDB Version 12")
            export VERSION=12
            break;;
        *) 
            echo "invalid option $REPLY"
            break;;
    esac
done

echo ""
echo "Building the version '$VERSION' image locally..."
docker build \
    -t mccarthysean/timescaledb_backup_s3:latest-$VERSION \
    -t mccarthysean/timescaledb_backup_s3:$VERSION-$TAG_VERSION \
    --build-arg VERSION=$VERSION \
    .

# Push to Docker Hub (must have Docker version ^20 to use --all-tags)
# docker login --username=mccarthysean
echo ""
echo "Pushing the version '$VERSION' image to Docker Hub with all tags..."
echo "docker push --all-tags mccarthysean/timescaledb_backup_s3"
docker push --all-tags mccarthysean/timescaledb_backup_s3

exit 0
