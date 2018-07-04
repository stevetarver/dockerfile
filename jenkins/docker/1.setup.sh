#!/usr/bin/env bash
#
# Prepare for the Jenkins docker image build
#
# - Download the specified helm, docker versions
#
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
(
    cd ${MY_DIR}
    . config.sh

    # Create a temp dir for downloads
    mkdir temp

    # Download helm that matches our k8s cluster install
    HELM_ARCHIVE_NAME="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

    if [ ! -f "temp/${HELM_ARCHIVE_NAME}" ]; then
        cd temp
        echo "${ECHO_PREFIX} Downloading '${HELM_ARCHIVE_NAME}'"
        wget https://kubernetes-helm.storage.googleapis.com/${HELM_ARCHIVE_NAME} && \
        tar -zxvf ${HELM_ARCHIVE_NAME}
        cd ..
    else
        echo "${ECHO_PREFIX} '${HELM_ARCHIVE_NAME}' is present."
    fi

    # Download the docker client appropriate for our Jenkins image
    # We use a Debian Jenkins to match our ubuntu nodes
    # To see the Debian version of the Jenkins image
    #   docker run -it --rm jenkins/jenkins:lts cat /etc/os-release
    # 9 = stretch
    DOCKER_ARCHIVE_NAME="docker-${DOCKER_VERSION}.tgz"

    if [ ! -f temp/${DOCKER_ARCHIVE_NAME} ]; then
        cd temp
        echo "${ECHO_PREFIX} Downloading '${DOCKER_ARCHIVE_NAME}'"
        wget https://download.docker.com/linux/static/stable/x86_64/${DOCKER_ARCHIVE_NAME} && \
        tar -zxvf ${DOCKER_ARCHIVE_NAME}
        cd ..
    else
        echo "${ECHO_PREFIX} '${DOCKER_ARCHIVE_NAME}' is present."
    fi
)
