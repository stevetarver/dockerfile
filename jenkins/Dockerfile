# Docker Hub: https://hub.docker.com/r/jenkins/jenkins/
# Image use: https://github.com/jenkinsci/docker/blob/master/README.md
# Dockerfile: https://github.com/jenkinsci/docker/blob/master/Dockerfile
# NOTE: we need to run the debian image because we are mounting /var/run
FROM jenkins/jenkins:2.107.2

# Build system will provide arguments to identify source location/version
ARG GIT_REPO_NAME='NOT SPECIFIED'
ARG GIT_BRANCH_NAME='NOT SPECIFIED'
ARG GIT_COMMIT_HASH='NOT SPECIFIED'
ARG BUILD_TIMESTAMP='NOT SPECIFIED'

# Label image with source location/version
LABEL com.makara.build.repo=${GIT_REPO_NAME}
LABEL com.makara.build.branch=${GIT_BRANCH_NAME}
LABEL com.makara.build.timestamp=${BUILD_TIMESTAMP}
LABEL com.makara.build.commit-hash=${GIT_COMMIT_HASH}

USER root

COPY files/jenkins-prefix.sh /usr/local/bin/jenkins-prefix.sh
COPY files/executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
COPY files/plugins-to-install.txt /usr/share/jenkins/ref/plugins.txt
COPY temp/docker/docker /usr/bin/docker
COPY temp/linux-amd64/helm /usr/bin/helm

# `helm init` must be run outside of main run command.
# It produces an error trying to connect to tiller, will kill the run, but safe to ignore
RUN helm init; exit 0

# NOTES:
# - sudo allows jenkins.sh to manipulate groups for access to docker.sock; see files/jenkins-prefix.sh
# - jq provides functionality used by vfw and our first pipeline. check with those projects for removal
RUN apt-get update \
    && apt-get install -y sudo jq vim \
    && echo "jenkins ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/jenkins \
    && chmod 440 /etc/sudoers.d/jenkins \
    && sudo sed -i '2r /usr/local/bin/jenkins-prefix.sh' /usr/local/bin/jenkins.sh \
    && rm /usr/local/bin/jenkins-prefix.sh \
    && chmod 755 /usr/bin/docker \
    && chmod 755 /usr/bin/helm \
    && mkdir -p /etc/kubernetes \
    && /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install a suitable kube.config for helm
COPY files/kube.config /etc/kubernetes/kube.config
ENV KUBECONFIG /etc/kubernetes/kube.config

WORKDIR /
USER jenkins




