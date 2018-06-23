#!/usr/bin/env bash
#
# Push our newly built docker image to portr
#
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

(
    cd ${MY_DIR}
    . config.sh

    echo -n "Enter your portr account name: "
    read USER

    echo -n "Enter your portr account password: "
    read -s PASSWORD

    docker login -u ${USER} -p ${PASSWORD}

    docker push ${IMAGE_NAMETAG}

    docker logout
)
