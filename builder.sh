#!/bin/bash

# Parse the arguments
for arg in "$@"; do
    export "$arg"
done

# Test the environment variables
echo "Repository URL: $REPO_URL"
echo "Default Branch: $DEFAULT_BRANCH"
echo "Repository ID: $REPO_ID"

# Create Dockerfile
cat << EOF > Dockerfiles/Dockerfile-$REPO_ID
FROM node:20-alpine
WORKDIR /app
ENV PORT=9000
RUN apk add --no-cache git
RUN git clone $REPO_URL . && \
    git checkout $DEFAULT_BRANCH && \
    npm install
CMD ["npm", "run", "start"]
EOF

# Check if a volume with the given ID already exists
# if [[ "$(docker volume ls -q -f name=auto-deploy-$REPO_ID)" ]]; then
#     echo "Volume auto-deploy-$REPO_ID already exists."
# else
#     echo "Volume auto-deploy-$REPO_ID does not exists. Creating new one..."
#     docker volume create auto-deploy-$REPO_ID
# fi

# Check if a network interface named auto-deploy already exists
if [[ "$(docker network ls -q -f name=auto-deploy)" ]]; then
    echo "Network auto-deploy already exists."
else
    echo "Network auto-deploy does not exists. Creating new one..."
    docker network create --driver bridge --subnet 172.20.0.0/16 --gateway 172.20.0.1 auto-deploy
fi

# Check if a container with the given ID already exists
if [[ "$(docker ps -a -q -f name=$REPO_ID)" ]]; then
    echo "Container with ID $REPO_ID already exists. Updating it..."
    # Stop and remove the existing container
    docker stop $REPO_ID &>/dev/null && docker rm $REPO_ID &>/dev/null
    # Build docker image and tag it with the ID
    docker build --no-cache -t $REPO_ID -f Dockerfiles/Dockerfile-$REPO_ID .
    # Recreate the container with the new image
    docker run --name $REPO_ID --network auto-deploy --restart unless-stopped -d -p 9000 $REPO_ID &>/dev/null
else
    echo "Container with ID $REPO_ID does not exists. Creating new one..."
    # Build docker image and tag it with the ID
    docker build --no-cache -t $REPO_ID -f Dockerfiles/Dockerfile-$REPO_ID .
    # Create a new docker container and set volume to `auto-deploy-$REPO_ID`
    docker run --name $REPO_ID --network auto-deploy --restart unless-stopped -d -p 9000 $REPO_ID &>/dev/null
fi