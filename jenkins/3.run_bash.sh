#!/usr/bin/env bash
#
# Run the container in bash mode
#
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

(
    cd ${MY_DIR}
    . config.sh

    echo "${ECHO_PREFIX} Bashing into '${IMAGE_NAMETAG}'"
    docker run -it --rm ${IMAGE_NAMETAG} bash
)
