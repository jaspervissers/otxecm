# OpenText Extended ECM

[Extended ECM](https://www.opentext.com/products-and-solutions/products/enterprise-content-management/extended-ecm-platform) is the market leading Enterprise Content Management platform that integrates content and content management in leading business applications such as SAP, Salesforce and Microsoft.

This Helm chart supports the deployment of Extended ECM on Kubernetes platforms. It packages the Extended ECM chart (Content Server) and all necessary components (Archive Center, Core Archive Connector, Directory Services, Intelligent Viewing and PowerDocs)

Please, refer to the product release notes in OpenText My Support to make sure to only use supported environments for productive use.

## TL;DR

Untar the helm chart. Edit the `otxecm/platforms/<platform>.yaml` for the platform you are deploying on and update the `imageSource` field for your docker registry.

If you do not have a domain/DNS created and are using kubernetes load balancers for testing purposes, edit `otxecm/platforms/<platform>.yaml` and set ingress_enabled to false, and update the global `xxxxPublicUrl` fields to empty strings "".

If you have a domain/DNS, edit the `otxecm/platforms/<platform>.yaml` for your platform and update the various `xxxxPublicUrl` fields. You will need to create a kubernetes secret for your TLS certificate following the detailed instructions below in this document. You will need to enable a nginx controller and include a static IP for it.

Next, deploy the helm chart:

```console
helm install otxecm otxecm -f otxecm/platforms/<platform>.yaml -f otxecm/otxecm-image-tags.yaml
```

## Introduction

This chart bootstraps an [Extended ECM](https://www.opentext.com/products-and-solutions/products/enterprise-content-management/extended-ecm-platform) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Install [Docker](https://docs.docker.com/get-started) (to push and pull Container images)
- Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) CLI in your local environment
- Install [Helm](https://helm.sh/docs/using_helm/#installing-helm) toolset on local environment (use 3.02 or newer)
- Create Kubernetes cluster in your cloud infrastructure. Minimum of 3 nodes with 4 CPU and 15GB storage each is required for a non-production setup.
- A sp.pem certificate file for installations with Archive Server or Archive Core Connector must be created in the folder otxecm/charts/otcs/.
- **We have introduced the ability to set the timezone for the entire deployment. It is strongly recommended that you keep the entire deployment in the same time zone (regardless of whether it is completely containerized, split into multiple namespaces, a mix of containerized / managed or on-premise) as this could cause undesired side effects with processes going off at unexpected times, incorrect date/time stamping etc.**
  **In order to set this, the _timeZone_ value in the platform files needs to be modified. The default for the deployment is Etc/UTC. If you would like to change this, please ensure that you accurately set this value to a known supported value [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).**

## Validating the Chart

> **Tip**: List all releases using `helm list`

To test and check the chart:

```console
helm lint -f otxecm/platforms/<platform>.yaml otxecm
helm template -f otxecm/platforms/<platform>.yaml otxecm
helm install \
otxecm otxecm \
-f otxecm/platforms/<platform>.yaml \
-f otxecm/otxecm-image-tags.yaml \
--dry-run \
--debug
```

## Installing the Chart

You need to be in the folder that includes the `otxecm` chart folder.
To install the chart with a dynamically assigned release name:

```console
helm install \
otxecm \
-f otxecm/platforms/<platform>.yaml otxecm \
-f otxecm/otxecm-image-tags.yaml \
```

Replace `<platform>` with one of the supported platform files in that folder.

Edit the `otxecm/platforms/<platform>.yaml` to your needs (e.g., enable / disable Ingress, set domain names and host names)

The command deploys OpenText Extended ECM on the Kubernetes cluster together with necessary components (Directory Services, Archive Center, Core Archive Connector, Intelligent Viewing and PowerDocs). The [configuration](#configuration) section lists the parameters that can be configured during installation.

## Deploying with an existing kubernetes secret

The use of kubernetes secret file is intended for production deployments. Edit otxecm/example-secret.yaml and provide password values for any components you are using. For example, if you are not using otac (Archive Center) for storage, then you can ignore those passwords. Provided values must be base64 encoded, per kubernetes requirements. If you are encoding in Linux with the base64 command, make sure you do not include new line characters. For example:

```console
echo -n 'aBigLongStringToEncode' | base64 -w 0
```

Create the kubernetes secret with the following command:

```console
kubectl create -f otxecm/example-secret.yaml
```

Also provide the secret name in the `otxecm/<platform>.yaml` file. By default, the secret name in example-secret.yaml is otxecm-secrets, so the line in `otxecm/<platform>.yaml` would look like this:

```console
existingSecret:       &existing_secret            otxecm-secrets
```

The command to deploy the helm chart is the same as above.

> **Important:** When deploying using secrets, all keys specified in the example-secret.yaml must be set for the containers that you are using. The exception to this is optional components that you are not using. For example, if you are using an otxecm container in your deployment, but not otac (Archive Server) as storage, then you do not need the AC_CORE_PASSWORD key under the ##otcs section.

## Optionally deploying with the Master password

Intended for non-production environments, where you can set a unique password across all components. To set the Master password, edit the otxecm/platforms/<platform>.yaml file and define the &master_password.

You can overwrite the password for a specific component based on the tables below:

#### OTDS 

| Command Line Parameter                                                 | Description                                                         |
|------------------------------------------------------------------------|---------------------------------------------------------------------|
| --set otds.otdsws.otadminPassword=\<password>                               | Define the password for the otadmin@otds.admin user for the OTDS        |
| --set otds.otdsws.otdsdb.password=\<password>                               | Define the password for the otds-db                                     |

#### OTCS

| Command Line Parameter                                                 | Description                                                         |
|------------------------------------------------------------------------|---------------------------------------------------------------------|
| --set otcs.passwords.adminPassword=\<password>                              | Define the Content Server Administration Password                       |
| --set otcs.passwords.baPassword=\<password>                                 | Define the password for the bizadmin user for the Content Server        |
| --set otcs.passwords.appMonitorPassword=\<password>                         | Define the password for the appmonitor user for the Content Server      |
| --set otcs.passwords.scenarioOwnerPassword=\<password>                      | Define the password for the Scenario Owner user for the Content Server  |
| --set otcs.passwords.database.adminPassword=\<password>                     | Define the password for the admin user for the Content Server database  |
| --set otcs.passwords.database.password=\<password>                          | Define the password for the user that owns the Content Server database  |

#### OTACC

| Command Line Parameter                                                 | Description                                                         |
|------------------------------------------------------------------------|---------------------------------------------------------------------|
| --set otcs.passwords.otacc.corePassword=\<password>                         | Define the password for the  otacc user, if otacc is being used for storage|
| --set otacc.cloud.baPassword=\<password>                                    | Define the password for the Business Administrator in Core Archive         |
| --set otacc.connector.Password=\<password>                                  | Define the password for the internal  Core Archive Connector user          |

#### OTAC

| Command Line Parameter                                                 | Description                                                         |
|------------------------------------------------------------------------|---------------------------------------------------------------------|
| --set otac.database.adminPassword=\<password>                               | Define the password for the admin user for the Archive Center database     |
| --set otac.database.password=\<password>                                    | Define the password for the user that owns the Archive Center database     |
| --set otac.otds.password=\<password>                                        | Define the password for the administrator user for the OTDS                |

#### OTIV

| Command Line Parameter                                                 | Description                                                         |
|------------------------------------------------------------------------|---------------------------------------------------------------------|
| --set global.database.adminPassword=\<password>                             | Define the password for the admin user for the config, publication, publisher, and markup services                     |
| --set global.masterPassword=\<password>                                     | Define the master password for all the otiv services                       |
| --set otiv.amqp.rabbitmq.password=\<password>                               | Define the password for the messaging user for otiv-amqp                   |

#### OTPD

| Command Line Parameter                                                 | Description                                                         |
|------------------------------------------------------------------------|---------------------------------------------------------------------|
| --set otpd.adminPassword=\<password>                                        | Define the password for the admin user for the PowerDocs                   |
| --set otpd.userPassword=\<password>                                         | Define the password for the PowerDocs user                 |
| --set otpd.monitorUserPassword=\<password>                                  | Define the password for the monitorUser User for the PowerDocs             |
| --set otpd.apiUserPassword=\<password>                                      | Define the password for the apiUser User for the PowerDocs                 |
| --set otpd.database.adminPassword=\<password>                               | Define the password for the admin user for the PowerDocs database          |
| --set otpd.database.password=\<password>                                    | Define the password for the user that owns the PowerDocs database          |
| --set otpd.otcs.password=\<password>                                        | Define the password for the administrator user for the OTCS                |
| --set otpd.otds.password=\<password>                                        | Define the password for the administrator user for the OTDS                |

#### Databases

| Command Line Parameter                                                 | Description                                                         |
|------------------------------------------------------------------------|---------------------------------------------------------------------|
| --set otcs-db.password=\<password>                                          | Define the password for the otcs-db                                     |
| --set otac-db.password=\<password>                                          | Define the password for the otac-db                                     |
| --set otpd-db.password=\<password>                                          | Define the password for the otpd-db                                     |

## Sample Command Line Parameters

These are common command line parameters that can be used. Please view the specific chart `values.yaml` file for all available options. For example, look in otxecm/charts/otcs/values.yaml for all values to be used with the otcs chart.

| Command Line Parameter                                                 | Description                                                         | Example Values                            |
|------------------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------|
| --set otcs.image.name=\<name>                                           | Define the name of the Extended ECM Docker image   | otxecm, otxecm-documentum-sap        |
| --set otcs.image.tag=\<version>                                         | Define the Docker image tag / version of the Extended ECM image   | 22.3.0                                    |
| --set otac.image.tag=\<version>                                         | Define the Docker image / tag version of the Archive Center image   | 21.2.6                                    |
| --set otds.otdsws.image.tag=\<version>                                         | Define the Docker image / tag version of the Directory Services image             | 22.3.0                                    |
| --set otds.otdsws.otdsdb.url=\<url>                                         | Define the url to connect to the DB for the Directory Services             | jdbc:postgresql://otcs-db:5432/otdsdb                                    |
| --set otds.otdsws.otdsdb.username=\<name>                                         | Define the username for the otds-db             | postgres                                    |
| --set global.otac.enabled=\<boolean>                                           | Define if Archive Center gets deployed as container or not  (enabled by default)        | false, true                               |
| --set global.otiv.enabled=\<boolean>                                           | Define if Intelligent Viewing services are deployed (enabled by default)         | false, true                               |
| --set otcs.config.documentStorage.type=\<store>                                        | Define where the content gets stored (needed if otac.enabled=false) | database, otac, otacc, efs      |
| --set otcs.config.database.hostname=<host/IP>                                          | Define the hostname of the DB server (if it is outside the cluster) | IP address or fully qualified domain name |
| --set otcs.config.database.adminUsername=\<database admin>                                     | Define the admin username of the DB server  | postgres |
| --set otcs.config.port=\<port number>                                    | Defines the external port for the otcs kubernetes service. Cannot be changed after initial deployment. | 45312 |
| --set otds.port=\<port number>                                    | Defines the external port for the otds kubernetes service. Cannot be changed after initial deployment. | 16254 |
| --set otds.otcsPort=\<port number>                                    | Defines the external port for the otcs kubernetes service. Cannot be changed after initial deployment. This must match the otcs port defined for the otds helm chart. | 45312 |
| --set global.otcs-db.enabled=\<boolean>                                        | Define if Content Server Database gets deployed as container or not | false, true                               |
| --set global.otpd.enabled=\<boolean>                                           | Define if PowerDocs container is deployed          | false, true  |
| --set global.otpd-db.enabled=\<boolean>                                        | Define if PowerDocs container is deployed          | false, true  |
| --set otcs.contentServerFrontend.replicas=\<num>                        | Number of Content Server Frontend instances to start                | 1-n                                       |
| --set otcs.contentServerFrontend.resources.requests.cpu=\<num>          | Number of CPU to be requested for Content Server Frontend           | 1                                         |
| --set otcs.contentServerFrontend.resources.requests.memory=\<gigabytes> | Compute memory to be requested for Content Server frontend          | 1.5Gi                                     |
| --set otcs.contentServerFrontend.limits.requests.cpu=\<num>             | CPU limit for Content Server Frontend                               | 2                                         |
| --set otcs.contentServerFrontend.limits.requests.memory=\<gigabytes>    | Compute memory limit for Content Server frontend                    | 4Gi                                       |
| --set otcs.contentServerAdmin.resources.requests.cpu=\<num>             | Number of CPU to be requested for Content Server Frontend           | 1                                         |
| --set otcs.contentServerAdmin.resources.requests.memory=\<gigabytes>    | Compute memory to be requested for Content Server frontend          | 1.5Gi                                     |
| --set otcs.contentServerAdmin.limits.requests.cpu=\<num>                | CPU limit for Content Server Frontend                               | 2                                         |
| --set otcs.contentServerAdmin.limits.requests.memory=\<gigabytes>       | Compute memory limit for Content Server frontend                    | 4Gi                                       |
| --set otcs.containerLogLevel=\<string>                       | Define how much information is logged by the container setup. 'DEBUG' will also enable Content Server logs during and after the deployment. | DEBUG, INFO, WARNING, ERROR, CRITICAL                                       |
| --set otcs.sharedAddressSpaceNat.enabled=\<boolean>                             | Define whether to allow Tomcat internalProxies to accept 100.64.0.0/10 IP range(Carrier-grade NAT) | false, true                                       |
|

### Install with defined release name

To install the chart with the release name `my-release`:

```console
helm install my-release otxecm -f otxecm/platforms/<platform>.yaml \
-f otxecm/otxecm-image-tags.yaml
```

### Install with different Extended ECM docker image

To change the Extended ECM Docker image (e.g., Extended ECM = `otxecm`, Extended ECM Documentum for SAP = `otxecm-documentum-sap`):

```console
helm install \
otxecm \
-f otxecm/platforms/<platform>.yaml otxecm \
-f otxecm/otxecm-image-tags.yaml \
--set otcs.image.name=otxecm
```

### Install without Archive Center

To install the chart without the OpenText Archive Center container but use database content store use these parameters:

```console
helm install \
otxecm \
-f otxecm/platforms/<platform>.yaml otxecm \
--set global.otac.enabled=false \
--set otcs.config.documentStorage.type=database
```

To use external filesystem as content store (in fact these are volumes on the Kubernetes platform) you can do so by setting the `otcs.config.documentStorage.type` variable to `efs`. You may also need to adjust the `otcs.config.documentStorage.efsStorageClassName` variable (`gcp-nfs` is just an example from Google Cloud Platform).

```console
helm install \
otxecm \
-f otxecm/platforms/<platform>.yaml otxecm \
-f otxecm/otxecm-image-tags.yaml \
--set global.otac.enabled=false \
--set otcs.config.documentStorage.type=efs \
--set otcs.config.documentStorage.efsStorageClassName=gcp-nfs
```

### Install with existing Archive Center outside the Cluster

You may already have a central instance of Archive Center to use, or when using OTK you can use Core Archive (Archive Server cloud storage). To install the chart without the OpenText Archive Center container:

```console
helm install \
otxecm \
-f otxecm/platforms/<platform>.yaml otxecm \
-f otxecm/otxecm-image-tags.yaml \
--set global.otac.enabled=false \
--set otcs.config.otac.url=<URL>
```

To install the chart without the OpenText Archive Center container and use otacc (OpenText hosted platform only):

1. Install the Core Archive connector helm chart. Make sure to edit the values.yaml with your archive connection details.

```console
helm install \
otxecm otxecm \
-f otxecm/platforms/cfcr.yaml \
-f otxecm/otxecm-image-tags.yaml \
--set otcs.config.documentStorage.type=otacc \
--set otcs.config.otacc.archiveName=<desired unique archive name> \
--set otcs.config.otacc.collectionName=<desired unique collection name> \
--set otcs.passwords.otacc.corePassword=<core archive cloud password> \
--set otcs.config.otacc.coreUser=<core archive cloud username> \
--set global.otac.enabled=false \
--set global.otac-db.enabled=false \
--set global.otacc.enabled=true  \
--set otacc.cloud.baUser=<core archive cloud username> \
--set otacc.cloud.baPassword=<core archive cloud password> \
--set otacc.connector.password=<core archive connector password> \
--set otacc.cloud.url=https://saribung.otxlab.net \
--set otacc.connector.reregister=true
```

Replace fields marked in angle brackets `<>` with values for your deployment.

### Install with existing OpenText Directory Services outside the Cluster

To install the chart without the OpenText Directory Services container (because you have a central instance of Directory Services already deployed):

```console
helm install \
otxecm \
-f otxecm/platforms/<platform>.yaml otxecm \
-f otxecm/otxecm-image-tags.yaml \
--set global.otds.enabled=false
```

Replace global.otdsPublicUrl inside `otxecm/platforms/<platform>.yaml` with the url of your existing OTDS.
The OpenText Directory Services server url can be set with the helm parameter:
`--set otcs.config.otds.serverUrl="yourOTDSUrl.com"`

The OpenText Directory Services sign in url can be set with the helm parameter:
`--set otcs.config.otds.signInUrl="yourOTDSSignIn.com"`

Both serverUrl and signInUrl are defaulted to the global.otdsPublicUrl when using an external OTDS.

### Install with DNS names and HTTPS using a Kubernetes Ingress

Edit the `global` section in the `platforms/<platform>.yaml` in the Helm chart directory. You need to have DNS entries and certificates for SSL / HTTPS prepared. Some platforms may also need a static IP to be created upfront or an ingress controller such as nginx-ingress.

### Install with predefined deployment sizes

Inside the `sizings/` folder in the Helm chart directory you find several deployment size examples. You can use them to customize the resources in your deployment. For example:

```console
helm install \
otxecm \
-f otxecm/platforms/<platform>.yaml \
-f otxecm/otxecm-image-tags.yaml \
-f otxecm/sizings/<size>.yaml otxecm
```

Replace `<size>` with one of the desired size options available in the folder.
The existing values are only examples and can be changed as needed.

### Install with Oracle Database

#### _Important: Extended ECM (otxecm image) is the only component that support Oracle database. The remaining components will require a PostgreSQL database_

#### Extending the base image

To use an Oracle database, the base Extended ECM docker image needs to be extended. As an example, Dockerfile_extend_oracle is provided.

To extend the image, go to the folder where the Dockerfile_extend_oracle is located and run:\
`docker build -f Dockerfile_extend_oracle -t DESIRED_IMAGE_NAME:TAG --build-arg base_image=OTXECM_IMAGE:TAG .`

#### Deploying with an Oracle Database

There are a few parameters that need to be set to deploy with an Oracle database

Set the database type to oracle:\
`--set otcs.config.database.type=oracle`

Set the hostname and port to the values for the Oracle database:\
`--set otcs.config.database.hostname=example.com`\
`--set otcs.config.database.port=1521`

When using Oracle, the service name must be set to the service name of the pluggable database to be used:\
`--set otcs.config.database.oracle.serviceName=CS`

When setting the admin user do not use the sys user. Instead, the system user must be used:\
`--set otcs.config.database.adminUsername=system`

The path for the database file and its size must be set. Its path must exist on the system where the database is running, but the .dbf file cannot:\
`--set otcs.config.database.oracle.dbDataFileSpec=/opt/oracle/cs.dbf`\
`--set otcs.config.database.oracle.dbDataFileSize=100`

#### Using a Tnsnames file

If using a tnsnames.ora file to connect to the database, the parameter must be enabled and the file must be added to the otcs subchart folder:\
`--set otcs.config.database.oracle.loadTnsnames.enabled=true`\
`--set otcs.config.database.oracle.loadTnsnames.filename=tnsnames.ora`

The connection alias of the connection to be used in the tnsnames.ora file must also be set:\
`--set otcs.config.database.oracle.tnsnamesConnectionAlias=ORCL`
For example, in the provided tnsnames.ora file the tnsnamesConnectionAlias would be ORCL.

Note: the hostname, port, and service name will not need to be set in your deployment when using a tnsnames.ora file.

#### Deploying custom modules/language packs using Init Containers:
To install custom modules/language packs, it is necessary to build a Docker Init container.<br>
Please, refer to the Extended ECM Cloud Deployment Guide published at OpenText My Support for details on how to build a Docker Init container for your custom module/language pack.

There are a few parameters that need to be set before deployment<br>
Set customizations enable to true <br>
`--set otcs.config.customizations.enable=true`<br>

If the containers inside kubernetes cluster don't have access to the internet then set includeManifestInitContainer value to true and provide init container details of manifest file as shown below<br>
`--set otcs.config.customizations.includeManifestInitContainer=true`<br>

> **Note**: Steps for building manifest file init container are provided in `init_template/README.md`

Repeat the below 4 lines for each init container image, by incrementing index of initContainers

```console
--set otcs.initContainers[0].name='DESIRED_NAME_FOR_INIT_CONTAINER' \
--set otcs.initContainers[0].image.source='IMAGE_SOURCE' \
--set otcs.initContainers[0].image.name='IMAGE_NAME' \
--set otcs.initContainers[0].image.tag='IMAGE_TAG'
```

## Upgrading the Chart

Upgrade deployment with Helm:

```console
helm list
helm upgrade <RELEASE_NAME> otxecm
```

Replace `<RELEASE_NAME>` with your Helm chart release name (shown by `helm list`).

Note that if you're upgrading from 21.3 or earlier and the Intelligent Viewing chart has also been installed, first delete the Intelligent Viewing chart (e.g., helm delete otiv) prior to upgrading to the 21.4 since the otiv chart has been added as an otxecm subchart.

## Scaling the Deployment

The Content Server frontend deployment can be scaled to cover different load levels. Per default one replica is started for the Kubernetes stateful set `otcs-frontend`. To scale it to 2:

```console
kubectl scale sts otcs-frontend --replicas=2
```

## Uninstalling the Chart

To check the name of existing charts:

```console
helm ls
```

To completely uninstall/delete the `my-release` deployment including all persisted data:

```console
helm delete my-release
kubectl delete pvc --all
```
If OTAC was deployed remove configMap and job related to otac upgrade

```console
kubectl delete configmap otac-pre-upgrade-configmap

kubectl delete jobs otac-pre-upgrade-job
```

If OTIV was deployed remove all secrets and service accounts related to otiv

```console
kubectl delete sa otiv-job-sa otiv-pvc-sa

kubectl delete secret otiv-cs-secrets otiv-highlight-secrets otiv-job-sa-token otiv-publication-secrets otiv-publisher-secrets otiv-pvc-sa-token otiv-resource-secret
```

> **Important**: `kubectl delete pvc --all` will delete all the persistent data of your deployment (including database storage). Do this only if you want to start from scratch!

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

Basic configuration can be done in the `platforms` directory inside the Helm chart. There you find dedicated YAML files for each platform:

- `gcp.yaml` (for [Google Cloud Platform GKE](#example-installation-and-configuration-for-google-cloud-platform))
- `azure.yaml` (for Microsoft [Azure AKS](#example-installation-and-configuration-for-azure-aks))
- `aws.yaml` (for [Amazon AWS EKS](#example-installation-and-configuration-for-amazon-aws))
- `cfcr.yaml` (for Cloud Foundry Container Runtime)
- `minikube.yaml` (for [Minikube](#example-installation-and-configuration-for-minikube) on your local computer - this is not meant for productive use)
- `openshift.yaml` (for [RedHat OpenShift](#example-installation-and-configuration-for-redhat-code-ready-container))

Most importantly you have to adjust the following settings in these platform YAML files:

- Docker image repository
- enable or disable the use of Fully Qualified domain names (this requires to set the `ingressEnabled` to `true`)
- enable the use of SSL / HTTPS (this also requires to set the `ingressEnabled` to `true` and to specify the name of the Kubernetes secret: `ingressSSLSecret`)

For more advanced settings you can also review the `values.yaml` file in the Helm chart directory to adjust parameters for Extended ECM (Content Server) and its components (e.g., Archive Center, Directory Services, etc). The better alternative may be to pass changed values with the help of the `--set` option in the `helm install` command (and not modify the `values.yaml` directly).

Some examples:

```console
helm install \
otxecm \
--set otcs.image.name=otxecm\
-f otxecm/platforms/gcp.yaml otxecm \
-f otxecm/otxecm-image-tags.yaml

helm install \
otxecm \
--set global.otac.enabled=false \
--set otcs.config.documentStorage.type=database \
-f otxecm/platforms/gcp.yaml otxecm \
-f otxecm/otxecm-image-tags.yaml

helm install \
otxecm \
--set otcs.image.name=otxecm-sap-o365-sfdc \
--set otcs.contentServerFrontend.replicas=2 \
-f otxecm/platforms/gcp.yaml  \
-f otxecm/otxecm-image-tags.yaml
```

### Example Installation and Configuration for Google Cloud Platform

This example creates a cluster named `xecm-cluster` and uses SSL (HTTPS). You need to create the `fullchain.pem` certificate file and the private key file `privkey.pem` before (e.g., with certbot and Let's encrypt). Also you need to create a container registry in GCP and push the Extended ECM Docker image and its components ( e.g., Archive Center, Directory Services, Intelligent Viewing).

1. Login to GCP and set GCP Project and Compute/Zone

    ```console
    gcloud auth login --no-launch-browser
    gcloud config set project <YOUR PROJECT ID>
    gcloud config set compute/zone <YOUR COMPUTE ZONE>
    ```

1. Create Cluster

    ```console
    gcloud container clusters create xecm-cluster \
    --machine-type n1-standard-4 \
    --num-nodes 3 \
    --cluster-version <set-a-supported-version> \
    --enable-stackdriver-kubernetes \
    --enable-ip-alias
    ```

1. Configure `kubectl` for the created cluster

    ```console
    gcloud container clusters get-credentials xecm-cluster --zone <YOUR COMPUTE ZONE> --project <YOUR PROJECT ID>
    ```

1. Create a static IP address in GCP

    ```console
    gcloud compute addresses create xecm-ip --region <YOUR COMPUTE ZONE>
    ```

1. Create DNS Entries

    Now we register a DNS zone in GCP and create three records for Extended ECM, Archive Server and Directory Services that will all point to the static IP adress you have created in GCP in the step before (if you deploy without Archive Center you don't need a DNS record for it).

    Replace `xecm-cloud.com` with your registered Internet domain (DNS name). Also replace the Internet addresses below with the static IP you created before.

    ```console
    gcloud dns managed-zones create xecm-cloud \
    --dns-name="xecm-cloud.com" \
    --description="DNS Zone for Extended ECM Deployment" \
    --visibility=public

    gcloud dns record-sets transaction start --zone="xecm-cloud"

    gcloud dns record-sets transaction add 10.2.3.4 \
    --name="otac.xecm-cloud.com" \
    --ttl="5" \
    --type="A" \
    --zone="xecm-cloud"
    gcloud dns record-sets transaction add 10.2.3.4 \
    --name="otcs.xecm-cloud.com" \
    --ttl="5" \
    --type="A" \
    --zone="xecm-cloud"
    gcloud dns record-sets transaction add 10.2.3.4 \
    --name="otds.xecm-cloud.com" \
    --ttl="5" \
    --type="A" \
    --zone="xecm-cloud"

    gcloud dns record-sets transaction execute --zone="xecm-cloud"
    ```

1. Prepare Helm Chart Deployment

    ```console
    kubectl create secret tls xecm-secret --cert fullchain.pem --key privkey.pem
    ```

1. Deploy Ingress Controller

    You need to replace the IP address with the one you created before. The `proxy-body-size` parameter controls the maximum allowable request size. You may need to increase it to upload larger files.

    ```console
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm install otxecm ingress-nginx/ingress-nginx \
    --set rbac.create=true \
    --set controller.service.loadBalancerIP=<PUBLIC FACING IP> \
    --set controller.config.proxy-body-size=1024m
    ```

1. Deploy Helm Chart

    ```console
    helm install otxecm -f otxecm/platforms/gcp.yaml otxecm -f otxecm/otxecm-image-tags.yaml
    ```

Access Directory Services and Content Server frontends with these URLs:

- Content Server: `https://otcs.<DOMAIN_NAME>/cs/cs`
- Directory Services: `https://otds.<DOMAIN_NAME>/otds-admin`

To shutdown the deployment and delete the cluster do the following (replace the `<RELEASE_NAME>` with the release names `helm list` returns):

```console
helm list
helm delete <RELEASE_NAME>
helm delete otxecm
kubectl delete pvc --all
gcloud container clusters delete xecm-cluster --zone <YOUR COMPUTE ZONE>
gcloud compute addresses delete xecm-ip --region <YOUR COMPUTE ZONE>
```

> **Important**: `kubectl delete pvc --all` will delete all the persistent data of your deployment (including database storage). Do this only if you want to start from scratch!

### Example Installation and Configuration for Amazon AWS

This example creates a cluster named <AWS_CLUSTER_NAME> and uses TLS (SSL). You need to create the TLS certificate on the AWS web portal using the `Certificate Manager` service. You need to create a docker container registry either on AWS or elsewhere that is accessible to AWS. Make sure the docker images you are using are pushed and available.

1. Create Cluster

    ```console
    eksctl create cluster \
    --name <AWS_CLUSTER_NAME> \
    --version 1.19 \
    --region <YOUR COMPUTE ZONE> \
    --nodegroup-name <AWS_CLUSTER_NAME>-workers \
    --node-type t3.xlarge \
    --nodes 3 \
    --nodes-min 1 \
    --nodes-max 4 \
    --alb-ingress-access \
    --external-dns-access \
    --full-ecr-access \
    --managed
    ```

1. Configure `kubectl` for the created cluster

    If not done before: set AWS Credentials (you need AWS Access Key ID, and AWS Secret Access Key for this):

    ```console
    aws configure
    ```

    If you have not created the cluster with `eksctl` on the same computer before you need to manually create a kubeconfig entry:

    ```console
    aws eks --region <YOUR COMPUTE ZONE> update-kubeconfig --name <AWS_CLUSTER_NAME>
    ```

    Check that your new cluster is registered with `kubectl`:

    ```console
    kubectl config get-contexts
    ```

    If you have multiple contexts for your local `kubectl` you may need to switch to the one for your AWS cluster:

    ```console
    kubectl config use-context <AWS_CLUSTER_NAME>
    ```

    Check if kubectl can communicate with the Kubernetes Cluster in AWS:

    ```console
    kubectl version
    ```

1. Prepare Helm Chart Deployment

    Switch to the directory that includes your certificate files.

    ```console
    kubectl create secret tls <AWS_CLUSTER_NAME>-secret --cert fullchain.pem --key privkey.pem
    ```

1. Deploy Ingress Controller

    ```console
    helm repo add eks https://aws.github.io/eks-charts

    helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=<AWS_CLUSTER_NAME>
    ```

1. Deploy Helm Chart

    Now we can install the `otxecm` Helm chart:

    ```console
    helm install otxecm otxecm -f otxecm/platforms/aws.yaml -f otxecm/otxecm-image-tags.yaml
    ```

   The deployment of the Helm Chart triggers the creation of an ALB loadbalancer for the Kubernetes Ingress.

1. Configure DNS

    At this point you have to go to [AWS Route 53 DNS zone management](https://console.aws.amazon.com/route53/home) and create the DNS entries for OTDS, OTCS and OTAC and point them to the created load balancer (Alias)

    You can list hosted zones with this command:

    ```console
    aws route53 list-hosted-zones

    aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID>
    ```

    Replace `<ZONE_ID>` with the zone ID `aws route53 list-hosted-zones` returned.

    We need three DNS record sets:
    - OTDS (use name "otds")
    - Content Server frontend (use name "otcs")
    - Archive Center (use name "otac")

    For all choose the type "A - IPv4 address" and set "Alias" to yes. Select the ALB loadbalancer as "Alias Target".

Access Directory Services and Content Server frontends with these URLs:

- Content Server: `https://otcs.<DOMAIN_NAME>/cs/cs`
- Directory Services: `https://otds.<DOMAIN_NAME>/otds-admin`

To shutdown the deployment follow these steps:

1. Remove the DNS entries that have aliases to the load balancer

    > **Important**: To shutdown the deployment you first have to remove the Aliases in the DNS records in AWS Route 53. Go to AWS Route 53 and delete the Record Sets for otac, otcs, and otds you have created during deployment.

1. Delete the otxecm Helm chart

    > **Important**: delete first the otxecm Helm Chart - then the ALB Helm Chart - otherwise the ALB loadbalancer will not be deleted and you will run into issues if you delete the cluster.

    You can delete the otxecm Helm Chart like this (replace `<RELEASE_NAME>` with the release name `helm list` returns):

    ```console
    helm list

    helm delete <RELEASE_NAME>
    ```

1. Delete persistent storage (if you want to start from scratch)

    ```console
    kubectl delete pvc --all
    ```

    > **Important**: `kubectl delete pvc --all` will delete all the persistent data of your deployment (including database storage). Do this only if you want to start from scratch!

1. Delete the ALB Helm Chart

    You can delete the ALB Helm Chart like this (replace `<ALB_RELEASE_NAME>` with the release name `helm list` returns):

    ```console
    helm list -n kube-system

    helm delete -n kube-system <ALB_RELEASE_NAME>
    ```

1. Delete the Kubernetes Cluster

    > **Important**: Remove everything you have created manually in AWS as this otherwise will not be deleted by `eksctl` and thus the deletion of the cluster will fail and you will end up with stale AWS resources you have to delete manually!
    > **Important**: Check if all Kubernetes resources are really freed up before deleting the cluster: `kubectl get pv` and `kubectl get pvc` should not list any resources. In doubt wait some time.

    Then you can delete the cluster with this command:

    ```console
    eksctl delete cluster --name <AWS_CLUSTER_NAME> --region <YOUR COMPUTE ZONE> --wait
    ```

Using EFS (external file system):

```console
aws efs create-file-system \
--creation-token <AWS_CLUSTER_NAME>  \
--performance-mode generalPurpose \
--throughput-mode bursting \
--region <YOUR COMPUTE ZONE>
```

Take note of the file system ID that is output by the command above.

Then deploy Helm Chart:

```console
helm install efs-provisioner stable/efs-provisioner \
--set efsProvisioner.efsFileSystemId=<YOUR FILE SYSTEM ID> \
--set efsProvisioner.awsRegion=<YOUR COMPUTE ZONE>
```

Check that a new Kubernetes storage class `aws-efs` has been created:

```console
kubectl get storageclasses
```

The storage class `aws-efs` should be listed.

To delete the external file system:

```console
aws efs delete-file-system --file-system-id <YOUR FILE SYSTEM ID>
```

### Example Installation and Configuration for Azure AKS

This example creates a cluster named `xecm-cluster` and uses TLS (SSL). You need to create the TLS certificate with Let's Encrypt, or some other method that makes available fullchain.pem and privatekey.pem files. You need to create a docker container registry either on Azure or elsewhere that is accessible to Azure. Make sure the docker images you are using are pushed and available.

1. Create Resource Group

    Replace `myresourcegroup` with your own resource group name and `westeurope` with your preferred Azure location.

    ```console
    az group create --name myresourcegroup --location westeurope
    ```

1. Create Cluster

    Alternately, you can create a kubernetes cluster with the Azure web portal.

    Replace `myresourcegroup` with the resource group name your created before and `westeurope` with your preferred Azure location. Also replace `myregistry` with the name of your container registry in Azure.

    ```console
    az aks create \
    --name xecm-cluster \
    --resource-group myresourcegroup \
    --kubernetes-version <set-a-supported-version> \
    --node-count 3 \
    --node-vm-size Standard_B4ms \
    --attach-acr myregistry \
    --dns-name-prefix xecm \
    --location westeurope
    ```

1. Configure `kubectl` for the created cluster

    Replace `xecm-cluster` with the name of the cluster you created in the step before and `myresourcegroup` with the resource group name your created before.

    ```console
    az aks get-credentials \
    --name xecm-cluster \
    --resource-group myresourcegroup
    ```

1. Connect Azure Kubernetes cluster with the Azure container repository

    ```console
    az aks update \
    --name xecm-cluster \
    --resource-group myresourcegroup \
    --attach-acr extendedecm
    ```

1. Create a static IP address in Azure

    Replace `xecm-cluster` with the name of the cluster you created in the step before and `myresourcegroup` with the resource group name your created before. After the IP is created, you will need to point your dns for any domains being used to this IP.

    ```console
    az network public-ip create \
    --name xecm-ip \
    --resource-group MC_myresourcegroup_xecm-cluster_westeurope \
    --allocation-method static \
    --query publicIp.ipAddress \
    --sku Standard \
    -o tsv
    ```

1. Prepare Helm Chart Deployment

    Create a kubernetes secret from your TLS certificate files.

    ```console
    kubectl create secret tls xecm-secret --cert fullchain.pem --key privkey.pem
    ```

1. Deploy Ingress Controller

    Replace the IP address with the one created previously.

    ```console
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm install otxecm-ingress ingress-nginx/ingress-nginx \
    --set rbac.create=true \
    --set controller.service.loadBalancerIP=<YOUR STATIC IP ADDRESS>
    ```

1. Deploy Helm Chart

    Edit the otxecm/platforms/azure.yaml file and update the imageSource to match your container registry. Edit your public hostnames to match what you are using.

    ```console
    helm install otxecm -f otxecm/platforms/azure.yaml otxecm -f otxecm/otxecm-image-tags.yaml
    ```

Access Directory Services and Content Server frontends with these URLs:

- Content Server: `https://<OTCS_DOMAIN_NAME>/cs/cs`
- Directory Services: `https://<OTDS_DOMAIN_NAME>/otds-admin`

To shutdown the deployment and delete the cluster do the following (replace the `<RELEASE_NAME>` with the release names `helm list` returns):

```console
helm list
helm delete <RELEASE_NAME>
helm delete otxecm-nginx
kubectl delete pvc --all
az aks delete --name xecm-cluster --resource-group myresourcegroup
```

> **Important**: `kubectl delete pvc --all` will delete all the persistent data of your deployment (including database storage). Do this only if you want to start from scratch!

### Example Installation and Configuration for Minikube (for NON-production use)

This example creates a minikube 1-node cluster and pulls images from Docker Hub with the minikube internal docker installation.
You have to replace the "DOCKER_" placeholders with your docker hub credentials.

1. Create Cluster

    On initial start provide the memory and CPU requirements:

    ```console
    minikube start --memory 16384 --cpus 4
    minikube status
    ```

    On follow-up starts you don't need to specify memory and CPU - it is remembered by Minikube:

    ```console
    minikube start
    ```

1. Create Kubernetes secret for Docker registry

    ```console
    kubectl create secret docker-registry regcred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username="<DOCKER_ACCOUNT>" \
    --docker-password="<DOCKER_PASSWORD>" \
    --docker-email=<DOCKER_EMAIL>
    ```

1. Create a tunnel to the local computer / browser

    Start a second shell and tunnel the Kubernetes services to the local computer.

    ```console
    minikube tunnel
    ```

1. Deploy Helm Chart

    Then you can install the helm chart in the first shell (using the database as a document storage type):

    ```console
    helm install otxecm otxecm \
    --set otcs.image.name=otxecm \
    --set global.otac.enabled=false \
    --set otcs.config.documentStorage.type=database \
    -f otxecm/platforms/minikube.yaml \
    -f otxecm/otxecm-image-tags.yaml
    ```

    Wait until the pods are running and the services are available:

    ```console
    kubectl get pods -w
    kubectl get service -w
    ```

You can lookup the endpoints of the Content Server frontends and PowerDocs in the column "EXTERNAL-IP"
and add the port that is listed in the "PORT(S)" column (the number in front of the colon)

> **Tip**: You have to add `/otds-admin` to the Directory Services URL and `/cs/cs` to the Content Server URL.

To shutdown the deployment and delete the cluster do the following (replace the `<RELEASE_NAME>` with the release name `helm list` returns):

```console
helm list
helm delete <RELEASE_NAME>
kubectl delete pvc --all
minikube tunnel --cleanup=true
minikube stop
minikube delete
```

> **Important**: `kubectl delete pvc --all` will delete all the persistent data of your deployment (including database storage). Do this only if you want to start from scratch!

### Example Installation and Configuration for RedHat Code Ready Container (for NON-production use)

Download CRC and the pull secret from the [RedHat CRC website](https://cloud.redhat.com/openshift/install/crc/installer-provisioned).

You may need to create a (free) account to get access.

1. Check to Code Ready Container (crc) is properly installed

    ```console
    crc version
    ```

1. Setup and Start crc

    Depending on the size of your machine you can tweak the parameters for memory (`-m`) and number of CPUs (`-c`).

    ```console
    crc setup

    crc start -c 6 -m 32768 -p ~/Downloads/pull-secret
    ```

    > **Important**: Take note of the output of the `crc start` command - it shows you the **admin password** for the cluster you need in the next steps.

1. Setup OpenShift and login

    You need to provide the admin user with `-u` and the admin password with `-p`.

    ```console
    eval $(crc oc-env)

    oc login -u kubeadmin -p <YOUR ADMIN PASSWORD> https://api.crc.testing:6443
     ```

    To check versions and see which nodes got created you can use these commands (this is optional):

    ```console
    oc version

    kubectl cluster-info

    kubectl get nodes
    ```

1. Setup OpenShift Project & Policies

    Run your deployment in an own OpenShift project and use `otxecm` as the name of this project. This will also create a Kubernetes namespace with that name. If you have not yet created a project named `otxecm` do so with this command:

    ```console
    oc new-project otxecm
    ```

    Otherwise switch to your existing `otxecm` project with this command:

    ```console
    oc project otxecm
    ```

    Optional you can check the content of the `otxecm` project and that the namespace have been created:

    ```console
    oc get project otxecm -o yaml

    kubectl get namespaces
    ```

    OpenShift also requires your deployment to run in its own **service account** - call it `otxecm-service-account` and use the `-n` option to define the project / namespace you created before:

    ```console
    oc create serviceaccount otxecm-service-account -n otxecm

    kubectl get serviceaccounts
    ```

    Now you have to set appropriate permissions:

    ```console
    oc adm policy add-scc-to-user privileged system:serviceaccount:otxecm:otxecm-service-account
    ```

1. Hack Persistent Volume Permissions

    This is a dirty hack to avoid permission problems with the persistent volumes CRC provides per default. This seems to be a known issue with CRC (the pre-provisioned persistent volumes are owned by root and don't give other access).

    You first have to find out the name of your Kubernetes node. Then you can open a debug session into that node to adjust the permissions of the 30 persistent volumes CRC has created at startup (`pv0001` - `pv0030`).

    ```console
    oc get nodes

    oc debug node/<node_name>

    cd /host/mnt/pv-data

    chmod 777 pv*

    exit
    ```

1. Start CRC Console

    ```console
    crc console
    ```

    Use these login information
    - Login: kubeadmin
    - Password: \<YOUR ADMIN PASSWORD>

    Select Home --> Projects in the menu on the left and select "otxecm".

1. Extended ECM Deployment

    Create secret for pulling Docker images from Docker Hub:

    ```console
    kubectl create secret docker-registry regcred \
    --docker-server=https://registry.opentext.com/v2/ \
    --docker-username="<OT_ACCOUNT>" \
    --docker-password="<OT_PASSWORD>" \
    --docker-email=<EMAIL>
    ```

    Deploy Helm Chart:

    ```console
    helm install otxecm -f otxecm/platforms/openshift.yaml otxecm -f otxecm/otxecm-image-tags.yaml

    watch kubectl get pods
    ```

1. Expose Kubernetes Services as routes in OpenShift

    ```console
    oc expose service otds

    oc expose service otcs-frontend
   ```

1. Access Directory Services and Content Server frontends

    <http://otds-otxecm.apps-crc.testing/otds-admin/>

    <http://otcs-frontend-otxecm.apps-crc.testing/cs/cs?func=llworkspace>

    <http://otcs-frontend-otxecm.apps-crc.testing/cs/cs/app>

1. Stop and Restart CRC

    To (temporarily) stop CRC:

    ```console
    crc stop
    ```

1. Finally delete CRC

    To (finally) delete CRC and the Kubernetes cluster:

    ```console
    crc delete
    ```

    A `crc delete` does not automatically remove the kubectl configurations - you have to do this manually to fully clean things up:

    ```console
    kubectl config delete-context otxecm/api-crc-testing:6443/kube:admin

    kubectl config delete-context default/api-crc-testing:6443/kube:admin
    ```

### Example Installation and Configuration for Canonical MicroK8s (for NON-production use)

This example creates a MicroK8s 1-node cluster and pulls images from Docker Hub.
You have to replace the "DOCKER_" placeholders with your docker hub credentials.

1. Installation

    MicroK8s runs best on Linux - e.g., an up-to-date Ubuntu or Fedora Linux distribution.

    First you need to install the snap package manager. It is required to then install MicroK8s.

    On Fedora Linux:

    ```console
    sudo dnf install snapd

    sudo ln -s /var/lib/snapd/snap /snap
    ```

    On Ubuntu Linux:

    ```console
    sudo apt install snapd
    ```

    Then install MicroK8s:

    ```console
    sudo snap install microk8s --classic --edge
    ```

    You need to enable a couble of MicroK8s modules that we need for our deployment:

    ```console
    microk8s enable helm3 dns storage dashboard rbac metallb
    ```

    During enabling of `metallb` you may be asked for an IP address range. Just confirm the proposed range:

    ```console
    Enter the IP address range (e.g., 10.64.140.43-10.64.140.49): 10.64.140.43-10.64.140.49
    ```

1. Create Cluster

    On initial start provide the memory and CPU requirements:

    ```console
    microk8s start

    microk8s status

    microk8s kubectl version
    ```

1. Create Kubernetes secret for Docker registry

    ```console
    microk8s kubectl create secret docker-registry regcred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username="<DOCKER_ACCOUNT>" \
    --docker-password="<DOCKER_PASSWORD>" \
    --docker-email=<DOCKER_EMAIL>
    ```

1. Deploy Helm Chart

    Then you can install the helm chart in the first shell (using the database as a document storage type):

    ```console
    microk8s helm3 install otxecm otxecm \
    --set otcs.image.name=otxecm \
    -f otxecm/platforms/microk8s.yaml \
    -f otxecm/otxecm-image-tags.yaml
    ```

    Wait until the pods are running and the services are available:

    ```console
    microk8s kubectl get pods -w
    microk8s kubectl get service -w
    ```

    > ***Important***: the load balancer services need an EXTERNAL-IP assigned. Otherwise you may not have enabled the `metallb` in the previous steps.

You can access Content Server frontends and Directory Services with these commands:

```console
http://<EXTERNAL_IP_OF_OTCS_FRONTEND>/cs/cs/app
http://<EXTERNAL_IP_OF_OTDS>/otds-admin
```

> **Tip**: You have to add `/otds-admin` to the OpenText Directory Services URL that is opened by minikube service otds.

You can also access the Kubernetes Dashboard

```console
microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443
```

Then you can then access the Dashboard at `https://127.0.0.1:10443`
You will be asked for a token that you can get by these commands:

```console
token=$(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)

microk8s kubectl -n kube-system describe secret $token
```

Copy the token into the browser page.

To shutdown the deployment and delete the cluster do the following (replace the `<RELEASE_NAME>` with the release name `helm list` returns):

```console
microk8s helm3 list
microk8s helm3 delete <RELEASE_NAME>
microk8s kubectl delete pvc --all
microk8s stop
```

> **Important**: `kubectl delete pvc --all` will delete all the persistent data of your deployment (including database storage). Do this only if you want to start from scratch!

To completely startover you can also reset your node / deployment.

```console
microk8s reset
```
