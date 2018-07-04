#!/usr/bin/env bash
#
# Download the current helm and build the Jenkins docker image
#
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
(
    cd ${MY_DIR}
    . config.sh

    echo "${ECHO_PREFIX} Building '${IMAGE_NAMETAG}'"
    docker build \
        --build-arg GIT_REPO_NAME=${GIT_REPO_NAME}      \
        --build-arg GIT_BRANCH_NAME=${GIT_BRANCH_NAME}  \
        --build-arg BUILD_TIMESTAMP=${BUILD_TIMESTAMP}  \
        --build-arg GIT_COMMIT_HASH=${GIT_COMMIT_HASH}  \
        -t ${IMAGE_NAMETAG} .
)