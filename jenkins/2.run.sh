#!/usr/bin/env bash
#
# Create/start a new container from the existing image
#
. 0.config.sh

JENKINS_HOME="$(pwd)/jenkins_home"

if [[ ! -d ${JENKINS_HOME} ]]; then
    echo "${ECHO_PREFIX} Creating the 'jenkins_home' directory"
    mkdir -m 775 ${JENKINS_HOME}
    echo "${ECHO_PREFIX} Enter your sudo password to set ownership for the 'jenkins_home' directory"
    sudo chown -R 1000 ${JENKINS_HOME}
fi

echo "${ECHO_PREFIX} Creating and starting '${CONTAINER_NAME}'"

# TODO: where to put the .kube dir
#     -v /data/.kube:/root/.kube          \

docker run --name ${CONTAINER_NAME}         \
    -p 8080:8080                            \
    -p 50000:50000                          \
    --restart=unless-stopped                \
    -v /var/run/docker.sock:/var/run/docker.sock  \
    -v ${JENKINS_HOME}:/var/jenkins_home    \
    -d ${IMAGE_NAME}
