# stevetarver addition:
# Insert at the top of /usr/local/bin/jenkins.sh
# Jenkins can run docker, but needs access to the docker mounted docker.sock
# to talk to the host daemon, for image caching/reuse and so other agents have
# access to the docker images we create.

# Don't modify groups if docker.sock doesn't exist - allow bashing into the container
if [[ -e /var/run/docker.sock ]]; then
    DOCKER_SOCK_GROUP=$(sudo stat -c "%G" /var/run/docker.sock)
    DOCKER_SOCK_GID=$(sudo stat -c "%g" /var/run/docker.sock)

    if [[ "UNKNOWN" = "${DOCKER_SOCK_GROUP}" ]]; then
        echo "Creating new 'host_docker' group with GID=${DOCKER_SOCK_GID} with access to docker.sock"
        sudo groupadd -r --gid ${DOCKER_SOCK_GID} host_docker
        echo "Adding user 'jenkins' to group 'host_docker'"
        sudo usermod -aG host_docker jenkins
    else
        # if 'jenkins' is already in the DOCKER_SOCK_GROUP
        if [[ $(getent group ${DOCKER_SOCK_GROUP} | grep &>/dev/null '\bjenkins\b') ]]; then
            echo "User 'jenkins' is in group '${DOCKER_SOCK_GROUP}' with access to docker.sock"
        else
            echo "Adding user 'jenkins' to group '${DOCKER_SOCK_GROUP} (${DOCKER_SOCK_GID})' for access to docker.sock"
            sudo usermod -aG ${DOCKER_SOCK_GROUP} jenkins
        fi
    fi
fi

# During the initial jenkins setup, we need to deploy the ceph volume and seed it
# with select files from the previous installation. To provide for this, we will
# specify env var INITIAL_START_DELAY to give us time to setup. When file changes
# are complete, the SRE will install the chart again without a sleep.
if [[ ! -z ${INITIAL_START_DELAY} ]]; then
    echo "Sleeping for ${INITIAL_START_DELAY} seconds to allow jenkins_home seeding"
    sleep ${INITIAL_START_DELAY}
fi
