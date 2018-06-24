#!/usr/bin/env bash
#
# Create/start a new container from the existing image
#
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
(
    cd ${MY_DIR}
    . config.sh

    JENKINS_HOME="$(pwd)/jenkins_home"

    if [[ ! -d ${JENKINS_HOME} ]]; then
        echo "${ECHO_PREFIX} Creating the 'jenkins_home' directory"
        mkdir -m 775 ${JENKINS_HOME}
        echo "${ECHO_PREFIX} Enter your OS sudo password to set ownership for the 'jenkins_home' directory"
        sudo chown -R 1000 ${JENKINS_HOME}
    fi

    echo "${ECHO_PREFIX} Creating and starting '${CONTAINER_NAME}'"

    ID=$(docker run --name ${CONTAINER_NAME}            \
        -p 8080:8080                                    \
        -p 50000:50000                                  \
        --restart=unless-stopped                        \
        -v /var/run/docker.sock:/var/run/docker.sock    \
        -v ${JENKINS_HOME}:/var/jenkins_home            \
        -d ${IMAGE_NAMETAG})

    echo "${ECHO_PREFIX} Logs for '${CONTAINER_NAME}'"
    docker logs -f ${ID}
)
