FROM jenkins/jenkins:2.60.2-alpine

ARG kube_version=1.5.3

USER jenkins
COPY plugins-to-install.txt /usr/share/jenkins/ref/plugins.txt
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy

# Notes:
# - another implementation: https://github.com/axltxl/docker-jenkins-dood
# - We are installing docker but not starting dockerd - the cli will talk to the
#   bind mounted docker.sock and have access to the host docker.
# - We are adding the jenkins user to the docker group to give it access to docker
# - For members of the docker group to talk to the docker.sock, the docker gid
#   must be the docker.sock gid. We reset the docker gid to that of docker.sock
#   in the docker entrypoint (jenkins.sh) so on each container run or access the
#   docker gid is updated to provide docker.sock access to the docker group.
# - The docker.entrypoint.sh is normally executed by the jenkins user. We add
#   jenkins to the sudoer list so it can update the docker gid.
# - the echo 2.0 line indicates to jenkins that it has already been configured and
#   skips the plugin selection stage.
# - Inhibiting the setup wizard with this line is not working in 2.60.2
#     echo 2.60.2 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state
#
# Default docker version for alpine 3.5.2 is 1.12.6-r0
# Would be nice to specify a version. Other versions don't appear to be available in this version of alpine
# would take some work to update apk to find the version
# ARG docker_version=1.12.6-r0
# docker=${docker-version}
# docker build --build-arg docker_version=1.12.0 -t jenkins .
#

USER root
WORKDIR /usr/local/bin

COPY linux-amd64/helm /usr/local/bin/helm
ADD https://storage.googleapis.com/kubernetes-release/release/v${kube_version}/bin/linux/amd64/kubectl /usr/local/bin/kubectl

RUN apk add --no-cache sudo shadow docker \
    && usermod -aG docker jenkins \
    && chmod 774 kubectl helm \
    && chgrp docker kubectl helm \
    && echo "jenkins ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/jenkins \
    && sed -i '3i# update docker gid to match docker.sock gid to allow jenkins access' jenkins.sh \
    && sed -i '4isudo groupmod -g $(stat -c "%g" /var/run/docker.sock) docker' jenkins.sh \
    && sed -i '5isudo chgrp docker /usr/bin/docker /usr/local/bin/kubectl /usr/local/bin/helm' jenkins.sh \
    && sed -i '6i' jenkins.sh \
    && install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

WORKDIR /
USER jenkins


