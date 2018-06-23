#!/usr/bin/env bash
#
# Convert a json short plugin list to a form usable by the
# Jenkins plugin installer.
#
# Get the list from the browser. E.g.
#  http://${JENKINS_URL}/pluginManager/api/json?depth=1&tree=plugins[shortName,version,active]
#
# in:  plugins-current.json
# out: files/plugins-to-install.txt
#
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
(
    cd ${MY_DIR}
    . config.sh

    jq -r '.plugins[] | select(.active) | "\(.shortName):\(.version)"' plugins-current.json | sort > files/plugins-to-install.txt
)
