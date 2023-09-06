#!/bin/bash

# Parse the arguments
for arg in "$@"; do
    export "$arg"
done

# Test the environment variables
echo "GIT_REPO: $GIT_REPO"
echo "GIT_BRANCH: $GIT_BRANCH"
echo "ID: $ID"

# Create Dockerfile
cat << EOF > Dockerfile-$ID
FROM node:20-alpine
WORKDIR /app
ENV PORT=9000
RUN apk add --no-cache git
RUN git clone $GIT_REPO . && \
    git checkout $GIT_BRANCH && \
    npm install
CMD ["npm", "run", "start"]
EOF

# Check if a volume with the given ID already exists
# if [[ "$(docker volume ls -q -f name=auto-deploy-$ID)" ]]; then
#     echo "Volume auto-deploy-$ID already exists."
# else
#     echo "Volume auto-deploy-$ID does not exists. Creating new one..."
#     docker volume create auto-deploy-$ID
# fi

# Check if a network interface named auto-deploy already exists
if [[ "$(docker network ls -q -f name=auto-deploy)" ]]; then
    echo "Network auto-deploy already exists."
else
    echo "Network auto-deploy does not exists. Creating new one..."
    docker network create --driver bridge --subnet 172.20.0.0/16 --gateway 172.20.0.1 auto-deploy
fi

# Check if a container with the given ID already exists
if [[ "$(docker ps -a -q -f name=$ID)" ]]; then
    echo "Container with ID $ID already exists. Updating it..."
    # Stop and remove the existing container
    docker stop $ID && docker rm $ID
    # Build docker image and tag it with the ID
    docker build --no-cache -t $ID -f Dockerfile-$ID .
    # Recreate the container with the new image
    docker run --name $ID --network auto-deploy --restart unless-stopped -d -p 9000 $ID
else
    echo "Container with ID $ID does not exists. Creating new one..."
    # Build docker image and tag it with the ID
    docker build --no-cache -t $ID -f Dockerfile-$ID .
    # Create a new docker container and set volume to `auto-deploy-$ID`
    docker run --name $ID --network auto-deploy --restart unless-stopped -d -p 9000 $ID
fi


# /bin/bash

# # Parse the arguments
# for arg in "$@"; do
#     export "$arg"
# done

# # Test the environment variables
# echo "GIT_REPO: $GIT_REPO"
# echo "GIT_BRANCH: $GIT_BRANCH"
# echo "ID: $ID"

# # docker volume create auto-deploy-$ID
# # docker-compose -f docker-compose/node_20-alpine.yml up --no-recreate

# # Check if a container with the given ID already exists
# if [[ "$(docker ps -a -q -f name=$ID)" ]]; then
#     echo "Container with ID $ID already exists. Updating it..."
#     docker-compose -f docker-compose/node_20-alpine.yml up -d --no-deps --build $ID
# else
#     echo "Container with ID $ID does not exists. Creating new one..."
#     docker volume create auto-deploy-$ID
#     docker-compose -f docker-compose/node_20-alpine.yml up -d --no-recreate
# fi