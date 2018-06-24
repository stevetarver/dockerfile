#!/usr/bin/env bash
#
# Push our newly built docker image to docker hub
#
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
(
    cd ${MY_DIR}
    . config.sh

    docker login
    docker push ${IMAGE_NAMETAG}
    docker logout
)
