#!/usr/bin/env bash
#
# Stop running container and remove container/image
#
. 0.config.sh

RUNNING=$(docker inspect --format="{{ .State.Running }}" ${CONTAINER_NAME} 2> /dev/null)

if [ "$RUNNING" == "true" ]; then
    echo "$ECHO_PREFIX Stopping '$CONTAINER_NAME' container"
    docker stop $CONTAINER_NAME
else
    echo "$ECHO_PREFIX '${CONTAINER_NAME}' container is not running"
fi

if [[ "$(docker ps -aq --filter name=${CONTAINER_NAME} 2> /dev/null)" != "" ]]; then
    echo "$ECHO_PREFIX Removing '${CONTAINER_NAME}' container"
    docker rm -v ${CONTAINER_NAME}
else
    echo "$ECHO_PREFIX '${CONTAINER_NAME}' container does not exist"
fi

if [[ "$(docker images -q ${IMAGE_NAME} 2> /dev/null)" != "" ]]; then
    echo "$ECHO_PREFIX Removing '${IMAGE_NAME}' image"
    docker rmi ${IMAGE_NAME}
else
    echo "$ECHO_PREFIX '${IMAGE_NAME}' image does not exist"
fi

if [[ "$(docker images -q -f dangling=true 2> /dev/null)" != "" ]]; then
    echo "$ECHO_PREFIX Removing dangling docker images"
    docker rmi $(docker images -q -f dangling=true)
fi


echo "$ECHO_PREFIX Removing 'jenkins_home' directory"
rm -rf jenkins_home

echo "$ECHO_PREFIX Removing 'helm' artifacts"
rm -rf linux-amd64
rm helm-v*
