#!/usr/bin/env bash
#
# Exec a bash shell on a running container
#
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
(
    cd ${MY_DIR}
    . config.sh

    echo "${ECHO_PREFIX} Bashing into '${IMAGE_NAMETAG}'"
    ID=$(docker ps -q \
        --filter "label=com.makara.build.repo=${GIT_REPO_NAME}" \
        --filter "label=com.makara.build.commit-hash=${GIT_COMMIT_HASH}")

    docker exec -it ${ID} bash
)
