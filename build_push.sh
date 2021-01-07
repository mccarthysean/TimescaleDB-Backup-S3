#!/bin/bash

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
echo "docker-compose -f docker-compose.build.yml build"
docker-compose -f docker-compose.build.yml build

# Push to Docker Hub
# docker login --username=mccarthysean
echo ""
echo "Pushing the version '$VERSION' image to Docker Hub..."
echo "docker push mccarthysean/timescaledb_backup_s3:$VERSION"
docker push mccarthysean/timescaledb_backup_s3:$VERSION

exit 0
