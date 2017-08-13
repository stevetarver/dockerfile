FROM jenkins/jenkins:lts

USER root
ENV DEBIAN_FRONTEND noninteractive
ADD https://storage.googleapis.com/kubernetes-release/release/v1.5.3/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY linux-amd64/helm /usr/local/bin/helm
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils \
    && apt-get install -y --no-install-recommends sudo \
    && apt-get install -y --no-install-recommends libltdl7 \

USER jenkins

# Make jenkins a sudoer on the host for access to the docker binary                                                                                                                                                      && rm -rf /var/lib/apt/lists/*
RUN echo "jenkins ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/jenkins
ENV DEBIAN_FRONTEND teletype
