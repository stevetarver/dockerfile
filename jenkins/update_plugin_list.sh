#!/usr/bin/env bash
#
# Extract a list of installed plugins from a running Jenkins and
# build a plugin version list.
#
# This list will be used during docker image build to seed the image
# with the plugins we want in our base install.
#
# View all plugin information:
#   http://localhost:8080/pluginManager/api/json?depth=1
#
# More details on plugin install strategy at
#   https://github.com/jenkinsci/docker/blob/master/README.md
#
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
(
    cd ${MY_DIR}
    . config.sh

    # Point to the proper jenkins to fetch the plugin list
    JENKINS_URL='localhost:8080'
    #JENKINS_URL='http://jenkins.t3dev.dom/'

    echo -n "Enter the Jenkins account name: "
    read USER

    echo -n "Enter the Jenkins account password: "
    read -s PASSWORD

    wget --user=${USER}                         \
        --password=${PASSWORD}                  \
        --auth-no-challenge                     \
        --output-document=plugins-current.json  \
        --quiet                                 \
        "http://${JENKINS_URL}/pluginManager/api/json?depth=1&tree=plugins[shortName,version,active]"

    # Create a file of newline delimited pluginID:version pairs
    #  credentials:1.18
    #  maven-plugin:2.7.1

    jq -r '.plugins[] | select(.active) | "\(.shortName):\(.version)"' plugins-current.json | sort > files/plugins-to-install.txt
)
