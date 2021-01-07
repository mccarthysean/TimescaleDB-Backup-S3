#!/bin/bash

# Build and tag image locally in one step. 
# No need for docker tag <image> mccarthysean/ijack:<tag>
echo ""
echo "Building the image locally..."
echo "docker-compose -f docker-compose.build11.yml build"
docker-compose -f docker-compose.build11.yml build

# Push to Docker Hub
# docker login --username=mccarthysean
echo ""
echo "Pushing the image to Docker Hub..."
echo "docker push mccarthysean/timescaledb_backup_s3:11"
docker push mccarthysean/timescaledb_backup_s3:11

# # Deploy to the Docker swarm and send login credentials 
# # to other nodes in the swarm with "--with-registry-auth"
# echo ""
# echo "Deploying to the server..."
# echo "docker stack deploy --with-registry-auth -c docker-compose.example.yml timescale11"
# docker stack deploy --with-registry-auth -c docker-compose.example.yml timescale11
