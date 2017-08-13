## Overview

Build a derived jenkins docker image configured specifically for my use

## References

* [Jenkins Docker Hub page](https://hub.docker.com/r/jenkins/jenkins/)
* [Legacy Jenkins Docker Hub page - good customization ideas](https://hub.docker.com/_/jenkins/)


## Adding plugins

From your current Jenkins, or a suitable version:

wget http://<jenkins>/pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins

This command will show all information available

http://<jenkins>/pluginManager/api/xml?depth=1

Create a plugins.txt file that contains entries like pluginID:version from results above

```
credentials:1.18
maven-plugin:2.7.1
```

And in derived Dockerfile just invoke the utility plugin.sh script

FROM jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt

## Set build executer count

Setting the number of executors
You can specify and set the number of executors of your Jenkins master instance using a groovy script. By default its set to 2 executors, but you can extend the image and change it to your desired number of executors :

```
executors.groovy

import jenkins.model.*
Jenkins.instance.setNumExecutors(5)
```
and Dockerfile
```
FROM jenkins
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
```

## The Dockerfile
