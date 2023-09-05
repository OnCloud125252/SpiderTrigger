#!/bin/bash

# Parse the arguments
for arg in "$@"; do
    export "$arg"
done

# Test the environment variables
echo "GIT_REPO: $GIT_REPO"
echo "GIT_BRANCH: $GIT_BRANCH"
echo "ID: $ID"

# docker volume create auto-deploy-$ID
# docker-compose -f docker-compose/node_20-alpine.yml up --no-recreate

# Check if a container with the given ID already exists
if [[ "$(docker ps -a -q -f name=$ID)" ]]; then
    echo "Container with ID $ID already exists. Updating it..."
    docker-compose -f docker-compose/node_20-alpine.yml up -d --no-deps --build $ID
else
    echo "Container with ID $ID does not exists. Creating new one..."
    docker volume create auto-deploy-$ID
    docker-compose -f docker-compose/node_20-alpine.yml up -d --no-recreate
fi