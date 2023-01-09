# OpenText Extended ECM

## Additional directions for upgrading from earlier versions are below

## Upgrading from 21.4.x or 22.1.x

## _NOTE: In 21.4 and later, Content Server logging is not automatically enabled for the otxecm container during upgrades. You will need to set Content Server logs to the desired level before upgrading._

1. Make any appropriate backups, using tools like velero, for backing up existing pvcs. Content server log pvc's(cs-persist-otcs-admin-n and cs-persist-otcs-frontend-n) can be excluded from backup by applying necessary labels to them based on backup tool you are using.
```console
Eg: kubectl label pvc <pvc-name> labelkey=labelvalue
```

1. The 22.2 or later otxecm helm chart uses a newer otds docker image and helm chart. The otds database and user must be created before deploying the helm chart. For production environments, you must manually create the otds database and user in the postgres database. For test/demo purposes, the otds helm chart can share the otcs-db postgres database, and will do this by default. When upgrading an existing test environment, you will need to make the otds database with the following commands:

    ```console
    kubectl exec -it otcs-admin-0 -- bash
    psql -h otcs-db -p 5432 -U postgres -W
    create database otdsdb;
    \q
    exit
    ```

    A full upgrade command might look something like below for a basic deployment using database storage. Note that the various child chart 'enabled' values have changed from 'otcs-db.enabled' to 'global.otcs-db.enabled'.

    ```console
    helm upgrade <deployment name> otxecm \
    -f otxecm/platforms/<platform>.yaml \
    -f otxecm/otxecm-image-tags.yaml \
    --set otcs.config.documentStorage.type=database \
    --set global.otcs-db.enabled=true \
    --set global.otac.enabled=false \
    --set otcs.containerLogLevel=INFO \
    --set global.otiv.enabled=false \
    --set otds.otdsws.otdsdb.username=postgres \
    --set otds.otdsws.otdsdb.password=<password> \
    --set otds.otdsws.otdsdb.url='jdbc:postgresql://otdsDatabaseHostname:5432/<database name>'
    ```

    Optionally add these values (or update your kubernetes secret values) if the admin password has changed since last deployment:

    ```console
    --set otds.otdsws.otadminPassword=<password> \
    --set otcs.passwords.adminPassword=<password> \
    --set otac.otds.password=<password>
    ```

1. Optionally after the upgrade is complete (check the OTDS pod log to make sure the user migration is complete), you can delete the old otds pvc, as it is no longer used:

    ```console
    kubectl delete pvc otds-data-otds-0
    ```

## Upgrading from 21.2.x or 21.3.x

### If upgrading from an earlier version, please refer to Upgrading from 21.1.x below

These steps are required in addition to the steps in [Upgrading from 21.4.x or 22.1.x](#upgrading-from-214x-or-221x).

1. If the Intelligent Viewing chart (otiv) has been installed to your target namespace, delete this helm chart release prior to upgrade since the Intelligent Viewing chart has been added as a subchart to the otxecm chart starting with 21.4.

    ```console
    helm delete <otiv-release-name>
    ```

2. Perform upgrade steps as above for migrating from 21.4 or 22.1.x.

3. After the helm chart upgrade. Run the following command to delete all kubernetes jobs:

    ```console
    kubectl delete jobs --all
    ```

## Upgrading from 21.1.x

### SPECIAL NOTE: If coming from 20.3 or earlier, please refer to the "OpenText Extended ECM CE  - Cloud Deployment Guide" available in OpenText My Support Portal

These steps are required in addition to the steps in [Upgrading from 21.4.x or 22.1.x](#upgrading-from-214x-or-221x), and should be done prior to deleting any statefulsets.

1. From the folder "migrate_from_21.1_or_earlier" copy the files migrate-job.yaml and migrate-pvc.yaml to the otxecm/templates folder. If you have more than one replica for the otcs frontend, you must edit the files and copy the frontend sections the appropriate number of times to match the number of frontends you have. The kubernetes job uses the alpine:3.12.1 image, and you must make this image available at the image source specified in otxecm/platforms/\<platform>.yaml. Alternately, you can edit the migrate-job.yaml directly, and specify where to obtain this image.

1. Delete the existing service for otcs-admin-0. This is required because we are turning this into a headless service (see <https://kubernetes.io/docs/concepts/services-networking/service/#headless-services>). If you do not do this, the upgrade will fail because we cannot set this to a headless service through the regular upgrade scenario

   ```console
   kubectl delete service otcs-admin-0
   ```

1. If the Intelligent Viewing chart (otiv) has been installed to your target namespace, delete this helm chart release prior to upgrade since the Intelligent Viewing chart has been added as a subchart to the otxecm chart starting with 21.4.

    ```console
    helm delete <otiv-release-name>
    ```

1. Perform upgrade steps as above for migrating from 21.4 or 22.1.x.

1. After the helm chart upgrade, delete the migrate-job.yaml and migrate-pvc.yaml files from otxecm/templates. Run the following command to delete all kubernetes jobs:

    ```console
    kubectl delete jobs --all
    ```

    You can also delete the pvcs with the following naming convention (both admin and frontend) as they are no longer needed after the upgrade:

    appdata-otcs-admin-0\
    config-otcs-admin-0\
    csapplications-otcs-admin-0

    ```console
    kubectl delete pvc appdata-otcs-admin-0 config-otcs-admin-0 csapplications-otcs-admin-0
    kubectl delete pvc appdata-otcs-frontend-0 config-otcs-frontend-0 csapplications-otcs-frontend-0
    ```
