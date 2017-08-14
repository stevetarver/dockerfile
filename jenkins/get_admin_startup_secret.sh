#!/usr/bin/env bash
#
# On initial Jenkins run, it requires you to enter a secret written to a file in
# the container. This will also be the admin user's password.
#
# This script simplifies fetching that secret
#
. 0.config.sh

docker exec -it -u root ${CONTAINER_NAME} cat /var/jenkins_home/secrets/initialAdminPassword