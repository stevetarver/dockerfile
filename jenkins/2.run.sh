#!/usr/bin/env bash
#
# Create/start a new container from the existing image
#
. 0.config.sh


echo "${ECHO_PREFIX} Creating and starting '${CONTAINER_NAME}'"

if [[ ! -d jenkins-data ]]; then
    mkdir jenkins-data
    # TODO: make this dir accessible by uid 1000
fi

# TODO: where to put the .kube dir
docker run --name ${CONTAINER_NAME}     \
    -p 8080:8080                        \
    -p 50000:50000                      \
    --restart=unless-stopped            \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(which docker):/usr/bin/docker  \
    -v jenkins-data:/var/jenkins_home   \
    -v /data/.kube:/root/.kube          \
    -d ${IMAGE_NAME}