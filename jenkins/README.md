A Jenkins derived image intended for Kubernetes deployment.

## Additions

Features

* docker
* helm
* a `kube.config` to allow helm deploys
* a vetted, matched plugin list

Facilities

* build scripts to support getting a local plugin list, admin secrets, etc.
* ability to pause jenkins initial deploy configuration to allow copying `jenkins_home` from another PVC.


## References

* [Docker Hub jenkins/jenkins image](https://hub.docker.com/r/jenkins/jenkins/)
* [Jenkins Image use](https://github.com/jenkinsci/docker/blob/master/README.md)
* [Jenkins Dockerfile](https://github.com/jenkinsci/docker/blob/master/Dockerfile)


## Build requirements

Build system:

* All build scripts are bash, but have only been tested on a Mac.
* Access to the 
* You must have `jq` installed to create the plugin list: `brew install jq`.

### General rules

**Use the officially supported Jenkins image.** Jenkins' images have gone through some growing pains. Use this image repo

* jenkins/jenkins:   [https://hub.docker.com/r/jenkins/jenkins/](https://hub.docker.com/r/jenkins/jenkins/)

These two have been deprecated in favor of the above

* jenkins:           [https://hub.docker.com/_/jenkins/](https://hub.docker.com/_/jenkins/)
* jenkinsci/jenkins: [https://hub.docker.com/r/jenkinsci/jenkins/](https://hub.docker.com/r/jenkinsci/jenkins/)

**Never install from a floating tag like `latest` or `lts`.** Jenkins is famous for broken new releases and breaking legacy functionality so we never want the version to shift underneath us. To tell if a new lts version is available:

```bash
# pull the latest lts version
docker pull jenkins/jenkins:lts

# get the lts version
docker run jenkins/jenkins:lts --version
2.107.1
```

When using this image, always refer to it be its version tag `2.107.2`, etc., and never `lts`.

## Build pipeline

This Docker image build system uses a pipeline of bash scripts:

1. `./1.setup.sh`: Download docker and helm
2. `./2.build.sh`: Build the docker image
1. `./3.run_bash.sh`: Run the image in bash mode to check command line tools
2. `./4.run.sh`: Run the image for developing a new plugin list or validation
3. `./5.exec_bash.sh`: Exec into a running container for validation
4. `./6.archive.sh`: Push the image to portr
5. `./7.teardown.sh`: Remove all temporary files, docker images and containers

For a basic run of the build pipeline, follow the Testing section below.

**NOTE** Don't archive the image unless you really want to replace it; then ensure the `config.sh` `JENKINS_BASE_IMAGE_TAG` and `OUR_REVISION` are appropriate.

## Testing

### Validate bash, docker, helm

After setup and build, `./3.run_bash.sh` and:

1. verify no errors reported
2. `docker` should show docker help
3. `helm` should show helm help

Exit the container, ensure the `jenkins_home` local directory is empty or does not exist, `./4.run.sh` and watch logs looking for errors. The first log line should show some kind of OS group/user modification for access to `docker.sock`. On a Mac, this will be:

```
Adding user 'jenkins' to group 'root (0)' for access to docker.sock

#...
# Last line is something like this
INFO: Jenkins is fully up and running
```

When initialization is complete, verify the local `jenkins_home` directory has contents, then `CTRL+C` to stop following logs and `./5.exec_bash.sh` and:

1. verify no errors reported
1. `docker images` should produce a list of images on the host


## Updating this image

This image may need to be updated when any of the following occur:

* You add a plugin to an existing Jenkins
* An interesting new Jenkins image appears - either bug fixes or additional functionality
* Cluster helm/tiller versions updated (will probably still work)
* Cluster docker version updated (will probably still work)

### Adding a Jenkins plugin

Jenkins plugin management is a tricky beast. Only the latest version of a plugin can be installed from the GUI, those plugins may have overlapping transitive dependencies, and any one version may be buggy and have a fast-follower to fix the issue.

We want to keep our Jenkins image and plugin list up to date so that a Persistent Volume loss, or other Jenkins mishap doesn't leave us without the ability to roll back to a known-good version. This means that we never update Jenkins or its plugins from the GUI, we update this image and use the "upgrade process".

If you want to upgrade a small number of plugins on a relatively recent Jenkins:

1. Run the current Jenkins docker image
2. Upgrade the plugins and test functionality
3. Browse to this url:
    ```
    http://{jenkins_dns_name}/pluginManager/api/json?depth=1&tree=plugins[shortName,version,active]
    ```
4. Copy that list to `plugins-current.json`
5. Run `./process_plugins_current.sh` to produce `files/plugins-to-install.txt`
6. Increment `OUR_REVISION` in `config.sh`
7. Build the Jenkins docker image and push to portr
8. Update the helm chart `deploy.sh` to use the new docker image
1. Apply the changes with the Jenkins upgrade process


### New Jenkins image

The supported Jenkins docker image is [`jenkins/jenkins`](https://hub.docker.com/r/jenkins/jenkins). We always build from a version tagged image - never `lts` or similar synonym for head. To see if there is a newer `lts` image:

```bash
# Ensure there are no aliases to jenkins/jenkins or you will not get the latest lts
ᐅ docker rmi jenkins/jenkins
#...
ᐅ docker rmi $(docker images -q -f dangling=true)
#...
ᐅ docker pull jenkins/jenkins:lts
#...
# Get the actual version of the lts image
ᐅ docker run --rm jenkins/jenkins:lts --version
2.107.1
```

Run the new Jenkins locally to develop the custom plugin list. There are a couple of ways to do this. The simplest is to:

1. Build the docker image using the new Jenkins version. In `config.sh`
    * Set `JENKINS_BASE_IMAGE_TAG` to the new version
    * Set `OUR_REVISION` to 0
1. Run the docker image, run through initial startup as described below.
2. Upgrade all plugins
3. Follow the process in "Adding a Jenkins plugin" section above.

The very manually intensive process for creating the initial plugin list is documented below. It runs through the Jenkins image startup process and has some other tricks that might be useful for special cases.

### Kubernetes cluster Helm updated

You can find the current helm version by bashing into the current Jenkins container and:

```bash
helm version
E0404 22:45:13.230851   27885 portforward.go:212] Unable to create listener: Error listen tcp6 [::1]:33289: bind: cannot assign requested address
Client: &version.Version{SemVer:"v2.5.1", GitCommit:"7cf31e8d9a026287041bae077b09165be247ae66", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.5.1", GitCommit:"7cf31e8d9a026287041bae077b09165be247ae66", GitTreeState:"clean"}
```

If the `Server` version doesn't match the `HELM_VERSION` defined in `config.sh`, especially if you are having helm problems, you may want to update the jenkins image.

1. Update `HELM_VERSION` to the new Server version in `config.sh`
2. Increment `OUR_REVISION` in `config.sh`
3. Create and push the new image
4. Update the image tag in our jenkins helm chart
5. Perform a standard Jenkin update (documented below)

### New Docker version

If Common Services changes the docker version on the k8s nodes, we will likely see no impact. It is good to keep both the client and server versions in sync, so perhaps this is only done when a new Jenkins image is created, or we actually see docker related problems in Jenkins.

* Change `DOCKER_VERSION` in config.sh
* Increment `OUR_REVISION` in config.sh
* Run through entire build process, starting with `./7.teardown.sh` to ensure we're grabbing a fresh docker client.
* Run through deploy process

### Creating the initial plugin list

The very manually intensive process used to create the initial plugin is left as doc in case needed in the future.

When you decide to attempt a new Jenkins version, the goal is to create a derived Jenkins image, from a specific Jenkins version tag, with a versioned set of plugins proven in this image. We will run through a more rigorous build to define those new plugin versions and then test the image. The first step is to remove our current plugin list from the build process. Comment out or remove the following lines from the Dockerfile:

```
COPY files/plugins-to-install.txt /usr/share/jenkins/ref/plugins.txt
    && /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt \
```

1. `./teardown.sh` to clean all artifacts
1. In the Dockerfile, update the `FROM jenkins/jenkins:2.107.1` to use the new version
2. In `config.sh`
    * Set `JENKINS_BASE_IMAGE_TAG` to the new version
    * Set `OUR_REVISION` to 0
1. Complete the Testing section above (setup, build, run_bash, run, exec_bash)
2. Run `get_admin_startup_secret.sh` to get the initialization password
3. Open [http://localhost:8080](http://localhost:8080)
4. Enter the admin secret and click "Continue"
5. On the "Getting Started" page, click "Select plugins to install"
6. Select only the following:
    * Folders
    * Build Timeout
    * Config File Provider
    * Credentials Binding
    * Timestamper
    * Workspace Cleanup
    * Gradle
    * HTML Publisher
    * Pipeline
    * GitHub Branch Source
    * Pipeline: GitHub Groovy Libraries
    * Pipeline: Stage View
    * Git
    * GitHub
    * Matrix Project
    * SSH Slaves
    * Matrix Authorization Strategy
    * PAM Authentication
    * LDAP
    * Role-based Authorization Strategy
    * Active Directory
1. Click "Install"
2. When installation is complete, fill in a local admin user that is easy to remember and click "Save and Finish", then "Start using Jenkins"
3. Click "Manage Jenkins" and then "Manage Plugins" and then the "Available" tab and select the following:
    * GitHub Authentication
    * Slack Notification
    * GitHub Pull Request Coverage Status
    * HTTP Request
    * Pipeline Utility Steps
    * GitHub Integration
    * Pipeline: Multibranch with defaults
    * HashiCorp Vault
    * Blue Ocean
    * Common API for Blue Ocean
    * Config API for Blue Ocean
    * Dashboard for Blue Ocean
    * Events API for Blue Ocean
    * Git Pipeline for Blue Ocean
    * GitHub Pipeline for Blue Ocean
    * Pipeline implementation for Blue Ocean
    * REST API for Blue Ocean
    * REST Implementation for Blue Ocean
    * Web for Blue Ocean
    * Compact Columns
    * Pipeline SCM API for Blue Ocean
    * Consul
    * Prometheus metrics
    * Console Badge
    * Amazon Web Services SDK
    * S3 publisher plugin
    * ThinBackup
1. Click "Install without restart". "Download now and install after restart" failed and lost all selections for me.
2. On the next page, check "Restart Jenkins when installation is complete and no jobs are running"
3. When installation and restart are complete, run `./update_plugin_list.sh` (ensure that script is pointing to localhost). This produces `files/plugins-to-install.txt` containing a short name plugin version list that Jenkins will use as a plugin base during image deployment.
4. Compare `files/plugins-to-install.txt` with the previous version in git to ensure all plugins are covered and we don't have excessive growth in plugins - we want a minimal list.
5. Compare the localhost Plugin Manager Installed plugins with the dev Jenkins to to catch plugins that were installed outside of this process AND should be installed. Note, for simplicity, you can focus on plugins whose "Enabled" checkbox is enabled. All other's are dependencies of a plugin with an enabled "Enabled" checkbox.
6. If additional plugins were found in the above two steps, install those plugins and re-run `./update_plugin_list.sh`. 
6. Enable the following two lines in the Docker file
    ```
    COPY files/plugins-to-install.txt /usr/share/jenkins/ref/plugins.txt

        && /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt \
    ```
1. Run `./7.teardown.sh` to provide a clean build environment for the build of the new image
2. Run `./1.setup.sh` and `./2.build.sh` and complete the Testing section above for `./3.run_bash.sh`, `./4.run.sh`, and `./5.exec_bash.sh`.
1. Login to your [local Jenkins](http://localhost:8080)
    1. Enter the admin secret and click "Continue"
    2. Click "Select plugins to install"
    3. On the "Getting Started" page, select "None" at the top of the page and click "Install"
    4. Create a memorable, local, admin user and click "Save and Finish"
    5. Click "Start using Jenkins"
    6. Look through the site for any problems, ensure plugins were installed, etc.
3. When everything passes:
    1. Run `./6.archive.sh` to push the image to portr
    3. Run `./7.teardown.sh` to clean up temp files
    3. Commit changes
1. Continue proving the image and helm chart in the Minikube section below


## Minikube chart & image validation

Minikube is a great place to evolve the Jenkins helm chart and to verify a new Jenkins image.

### Requirements

* Minikube installed: see [installation instructions](https://kubernetes.io/docs/tasks/tools/install-minikube/) and  [getting started guide](https://kubernetes.io/docs/getting-started-guides/minikube/).
* Helm installed: `brew install kubernetes-helm`

### Start Minikube with the proper Kubernetes version

Minikube can be thought of as a Kubernetes version manager; it can run many versions of Kubernetes. We will want to match our deploy cluster version, se we can log into the BEIB master server and:

```bash
root@LB1T3NK8SM13:~# kubectl version
Client Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.11", GitCommit:"b13f2fd682d56eab7a6a2b5a1cab1a3d2c8bdd55", GitTreeState:"clean", BuildDate:"2017-11-25T18:34:52Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.11", GitCommit:"b13f2fd682d56eab7a6a2b5a1cab1a3d2c8bdd55", GitTreeState:"clean", BuildDate:"2017-11-25T17:51:39Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
```

Now list minikube's supported versions:

```bash
ᐅ minikube version
minikube version: v0.22.0
ᐅ minikube get-k8s-versions
The following Kubernetes versions are available when using the localkube bootstrapper:
	- v1.9.4
	- v1.9.0
	- v1.8.0
	- v1.7.5
#...
```

**NOTE**: If you have run minikube with a different version, run `minikube delete` to remove that cluster.

The closest matching version is `1.7.5`, so we'll start minikube with that:

```bash
ᐅ minikube version
minikube version: v0.22.0
ᐅ minikube start --kubernetes-version v1.7.5
Starting local Kubernetes v1.7.5 cluster...
Starting VM...
Downloading Minikube ISO
 142.22 MB / 142.22 MB [============================================] 100.00% 0s
Getting VM IP address...
Moving files into cluster...
Downloading localkube binary
 138.70 MB / 138.70 MB [============================================] 100.00% 0s
 0 B / 65 B [----------------------------------------------------------]   0.00%
 65 B / 65 B [======================================================] 100.00% 0sSetting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
Loading cached images from config file.
```

Notes:

* If you have problems starting Minikube, you may need to restart your Mac, upgrade VirtualBox, or delete `~/.minikube` and try again.

Verify that all expected services are running:

```bash
ᐅ minikube addons list
- ingress: disabled
- addon-manager: enabled
- dashboard: enabled
- heapster: disabled
- registry: disabled
- registry-creds: disabled
- default-storageclass: enabled
- kube-dns: enabled
ᐅ kubectl get pods --all-namespaces
NAMESPACE     NAME                          READY     STATUS    RESTARTS   AGE
kube-system   kube-addon-manager-minikube   1/1       Running   0          1m
kube-system   kube-dns-910330662-8mqpv      3/3       Running   0          1m
kube-system   kubernetes-dashboard-4bw1w    1/1       Running   0          1m

# And then start the dashboard
ᐅ minikube dashboard
```

### Minikube setup

After minikube is installed and running, complete these steps to setup your minikube to use the Jenkins helm chart:

1. Verify your kubectl is pointing to the right Kubernetes cluster:
    ```bash
    ᐅ kubectl config current-context
    minikube
    ```
1. Create the `dev` and `control` namespaces. `dev` is where Jenkins lives and `control` is where we deploy services.
    ```bash
    kubectl create namespace control
    kubectl create namespace dev
    ```
1. Create the `portr-registry-credentials` for each namespace you want to deploy to (dev, control). When minikube starts, it points your kubectl to minikube - ensure you are pointing to minikube and run the `pl-cloud-infrastructure/kubernetes/tools/portr_registry_secret/add_portr_secret.sh` script and enter your portr credentials.
    ```bash
    ᐅ ./add_portr_secret.sh
    Enter the docker hub account name: stevetarver
    Enter the docker hub account password:
    Enter the k8s namespace (e.g. dev): dev
    ===> Generating dockerconfig.json
    ===> Base64 encoding dockerconfig.json
    ===> Generating docker_registry_secret.yaml
    ===> Creating docker-registry-credentials in dev
    secret "docker-registry-credentials" created
    ===> Removing temporary files
    ```
1. Set minikube node-type and location label to make it look like WOPR `dev`
    ```bash
    kubectl label --overwrite nodes --all location=local node-type=dev
    ```
1. Install Tiller (the server part of Helm) in minikube
    ```bash
    ᐅ helm init
    $HELM_HOME has been configured at /Users/starver/.helm.
    
    Tiller (the helm server side component) has been installed into your Kubernetes Cluster.
    Happy Helming!
    ```

### Chart validation

Run `./deploy.sh` in the helm chart directory:

```bash
ᐅ ./deploy.sh
===> Which environment are we in? [p]rod, [d]ev, [l]ocal: l
===> During the upgrade process, there will be a 'jenkins-next',
     a 'jenkins', and a 'jenkins-last'. Each has a corresponding
     DNS name and we will set the ingress accordingly.
===> Which jenkins ingress should be used? [n]ext, [c]urrent, [l]ast: n
===> During initial Jenkins setup, we set a large 'initial start delay'
     to allow copying the old jenkins_home to the new one.
===> Do you need to copy jenkins_home? [yn]: y
===> The releaseId is the integer between 'jenkins' and {location}
     above. You may pick one of the above, or increment the highest
     number for a fresh deploy.
===> Enter the releaseId: 0
===> Deploying jenkins-0-lb1 to lb1:dev
     image:    stevetarver/jenkins:2.107.2-r0
     ingress:  jenkins-next.local.dom
     delay:    999999s
     minikube: true
===> OK to continue? [yn]: y
```
Notes:

* Using environment 'local' which sets enables minikube and assumes an environment that looks like lb1.
* Using 'jenkins-next': this simulates the initial deploy of a 'next' Jenkins
* Copying 'jenkins_home': this pauses the container for a very long time, allowing you to seed jenkins_home and then groom it.
* ReleaseId: a monotonically increasing id inserted into helm release and deployed component names to keep the deployments separate. Normally, a 'jenkins-next' initial deploy will increment the highest releaseId and use that.

Verify the deployment:

2. Verify no helm errors reported and check to see that everything came up properly in the minikube `dev` namespace.
3. If you have errors pulling from portr, the problem is in your `portr-registry-credentials`, there are a couple of work arounds:
    1. Ensure you entered the right creds: Run `kubectl -n=dev delete secret portr-registry-credentials` and then re-run `./add_portr_secret.sh`.
    2. You can copy one from lb1 and apply it to minikube.
    1. Open a shell, run `eval $(minikube docker-env)` to connect the shell to the minikube docker, and then login to portr and pull the image. Change the Helm chart template deployment.yaml to `imagePullPolicy: IfNotPresent`, then run `./deploy.sh`.

At this point, you can continue with the initial Jenkins migration guide. You can download a dev or prod backup from AWS and copy that into the minikube Jenkins jenkins_home. Since we did not create a jenkins_home mount, you would open a shell, `eval $(minikube docker-env)`, then you can list the containers and use `docker cp` to copy the AWS backup to Jenkins. Then run `deploy.sh` again specifying that you don't need to copy jenkins_home.

The Jenkins minikube URL is identified with:

```bash
minikube service -n dev --url jenkins-1-lb1
http://192.168.99.100:30091
http://192.168.99.100:31739
```


If you want to play with a fresh Jenkins - in `deploy.sh`, specify that you don't want to copy jenkins_home, and when the container has started:

1. Get the initial Jenkins admin password:
    ```bash
    ᐅ kubectl get pods --namespace=dev
    NAME                             READY     STATUS    RESTARTS   AGE
    jenkins-1-lb1-4051827238-td9js   1/1       Running   0          20m
    ᐅ kubectl logs jenkins-1-lb1-4051827238-td9js --namespace=dev
    #...
    Please use the following password to proceed to installation:

    078ca579af5f456a93eddfc03958919f
    #...
    ```
1. Get the Jenkins minikube URL:
    ```bash
    minikube service -n dev --url jenkins-1-lb1
    http://192.168.99.100:30091
    http://192.168.99.100:31739
    ```
1. Log into the Jenkins console: open a browser on the above URL, enter the one-time password listed above, and complete Jenkins configuration as done above when developing the new docker image.



