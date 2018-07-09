#!/usr/bin/env bash

ECHO_PREFIX='===>'

# How we version: Retain the original distro name and tag; each
# build increments the revision. This allows us to easily trace
# our derived image back to the source: https://hub.docker.com/r/jenkins/jenkins/
export JENKINS_BASE_IMAGE_TAG='2.121.1'
export JENKINS_BASE_IMAGE_NAME='jenkins/jenkins'
export JENKINS_BASE_IMAGE_NAMETAG="${JENKINS_BASE_IMAGE_NAME}:${JENKINS_BASE_IMAGE_TAG}"
export OUR_REVISION=0

# This helm version must match the cluster's helm/tiller version
export HELM_VERSION=2.9.1

# This docker version should match the docker installed on the host node
export DOCKER_VERSION='18.03.1-ce'

export IMAGE_NAMETAG="stevetarver/jenkins:${JENKINS_BASE_IMAGE_TAG}-r${OUR_REVISION}"
export CONTAINER_NAME='jenkins'


# Docker image tagging variables
export BUILD_TIMESTAMP=$(TZ= date +%Y%m%d%H%M%S)

export GIT_REPO_URL=$(git config remote.origin.url)
export GIT_ORG_REPO_NAME=$(git config remote.origin.url | cut -f4-5 -d"/" | cut -f1 -d".")
export GIT_REPO_NAME=$(git config remote.origin.url | cut -d '/' -f5 | cut -d '.' -f1)
export GIT_BRANCH_NAME=$(git branch | grep \* | cut -d ' ' -f2-)
export GIT_COMMIT_HASH=$(git rev-parse HEAD)
