#!/usr/bin/env bash
#
# Download the current helm and build the Jenkins docker image
#
. 0.config.sh

# This helm version must match the cluster's tiller version
HELM_VERSION=2.2.3
HELM_ARCHIVE_NAME="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

echo "${ECHO_PREFIX} Building '${IMAGE_NAME}'"

if [ ! -f ${HELM_ARCHIVE_NAME} ]; then
    echo "${ECHO_PREFIX} Downloading '${HELM_ARCHIVE_NAME}'"
    wget https://kubernetes-helm.storage.googleapis.com/helm-v${HELM_VERSION}-linux-amd64.tar.gz
    tar -zxvf helm-v${HELM_VERSION}-linux-amd64.tar.gz
fi

docker build -t ${IMAGE_NAME} .
