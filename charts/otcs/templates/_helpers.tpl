{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "otcs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "otcs.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "otcs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "otcs.labels" -}}
app.kubernetes.io/name: {{ include "otcs.name" . }}
helm.sh/chart: {{ include "otcs.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "otcs.statefulset" -}}
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: {{ .Chart.Name }}-{{ .pod_type }}
  labels:
    app.kubernetes.io/component: {{ .Chart.Name }}-{{ .pod_type }}
    {{- include (printf "%s%s" .Chart.Name ".labels" ) . | nindent 4 }}
spec:
  serviceName: {{ .Chart.Name }}-{{ .pod_type }}
  {{- if eq .pod_type "admin" }}
  replicas: {{ .Values.contentServerAdmin.replicas }}
  podManagementPolicy: {{ .Values.contentServerAdmin.podManagementPolicy | quote }}
  {{- else if eq .pod_type "frontend" }}
  replicas: {{ .Values.contentServerFrontend.replicas }}
  podManagementPolicy: {{ .Values.contentServerFrontend.podManagementPolicy | quote }}
  {{- else if eq .pod_type "backend-search" }}
  replicas: {{ .Values.contentServerBackendSearch.replicas }}
  podManagementPolicy: {{ .Values.contentServerBackendSearch.podManagementPolicy | quote }}
  {{- else }}
  {{- printf "Unsupported pod_type of %s" .pod_type }}
  {{- fail }}
  {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/component: {{ .Chart.Name }}-{{ .pod_type }}
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/component: {{ .Chart.Name }}-{{ .pod_type }}
        app.kubernetes.io/instance: {{ .Release.Name }}
      {{- if .Values.podLabels }}
{{ toYaml .Values.podLabels | indent 8 }}
      {{- end }}
    spec:
      securityContext:
        # Since fsGroup is specified, all processes of the container are also part of the
        # supplementary group ID. The owner for volumes and any files created in the volume will
        # be Group ID 1000, which is otuser.
        fsGroup: 1000
      ## serviceAccountName defines the name of the service account the
      ## pods are running under. Normally that is 'default'
      serviceAccountName: {{ .Values.serviceAccountName }}
      terminationGracePeriodSeconds: 60
    {{- $length := len .Values.initContainers }}
    {{- if gt $length 0 }}
      initContainers:
      {{- range .Values.initContainers }}
        - name: {{ .name }}
        {{- if ( regexFind "\\/$" .image.source ) }}
          image: "{{ .image.source }}{{ .image.name }}:{{ .image.tag }}"
        {{- else }}
          image: "{{ .image.source }}/{{ .image.name }}:{{ .image.tag }}"
        {{- end }}
          command: ['sh', '-c', 'cp -R /opt/customizations/backup/* /opt/customizations/mount']
          imagePullPolicy: {{ $.Values.global.imagePullPolicy }}
          securityContext:
            allowPrivilegeEscalation: false
          volumeMounts:
            - mountPath: "/opt/customizations/mount"
              name: customization-volume-mount
        {{- end }}
      {{- end }}
      containers:
{{- if eq .Values.fluentbit.enabled true }}
      - name: fluentbit-container
{{- if not (regexFind "\\/$" .Values.image.source ) }}
        image: {{ .Values.fluentbit.image.source }}/{{ .Values.fluentbit.image.name }}:{{ .Values.fluentbit.image.tag }}
{{- else }}
        image: {{ .Values.fluentbit.image.source }}{{ .Values.fluentbit.image.name }}:{{ .Values.fluentbit.image.tag }}
{{- end }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
{{- if eq .Values.fluentbit.readinessProbe.enabled true }}
        readinessProbe:
          httpGet:
            path: /
            port: 2020
          initialDelaySeconds: {{ .Values.fluentbit.readinessProbe.initialDelaySeconds }}
          timeoutSeconds: {{ .Values.fluentbit.readinessProbe.timeoutSeconds }}
          periodSeconds: {{ .Values.fluentbit.readinessProbe.periodSeconds }}
{{- end }}
{{- if eq .Values.fluentbit.livenessProbe.enabled true }}
        livenessProbe:
          httpGet:
            path: /
            port: 2020
          initialDelaySeconds: {{ .Values.fluentbit.livenessProbe.initialDelaySeconds }}
          timeoutSeconds: {{ .Values.fluentbit.livenessProbe.timeoutSeconds }}
          periodSeconds: {{ .Values.fluentbit.livenessProbe.periodSeconds }}
          failureThreshold: {{ .Values.fluentbit.livenessProbe.failureThreshold }}
{{- end }}
        resources:
          limits:
            cpu: 300m
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        # fluent-bit port:
        - containerPort: 2020
        volumeMounts:
        - mountPath: "/opt/opentext/cs/logs"
          name: logs
        - mountPath:  /fluent-bit/etc/
          name: fluentbit-config
{{- end }}
      - name: {{ .Chart.Name }}-{{ .pod_type }}-container
{{- if not (regexFind "\\/$" .Values.image.source ) }}
        image: {{ .Values.image.source }}/{{ .Values.image.name }}:{{ .Values.image.tag }}
{{- else }}
        image: {{ .Values.image.source }}{{ .Values.image.name }}:{{ .Values.image.tag }}
{{- end }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        env:
        - name: OTCS_TYPE
          {{- if eq .pod_type "admin" }}
          value: primary
          {{- else }}
          value: secondary
          {{- end }}
        - name: OTCS_CONTAINER_LOG_LEVEL
          value: {{ .Values.containerLogLevel }}
        - name: OTCS_CONTAINER_DEBUG_LOG_ROLL
          value: {{ .Values.containerDebugLogRoll | quote }}
        - name: OTCS_ROLE
          value: {{ .pod_type }}
          {{- if (.Values.global.otds.enabled) }}
        - name: OTDS_SERVICE_NAME
          value: {{ include "otxecm.otdsServiceName" . }}
          {{- end }}
        - name: SHARED_ADDRESS_SPACE_NAT
          value: {{ .Values.sharedAddressSpaceNat.enabled | quote }}
        - name: TZ
          value: {{ .Values.config.timeZone }}
        - name: PGHOST
          value: {{ .Values.config.database.hostname | quote  }}
        - name: PGPORT
          value: {{ .Values.config.database.port | quote }}
        - name: PGUSER
          value: {{ .Values.config.database.adminUsername | quote }}
        - name: PGDATABASE
          value: {{ .Values.config.database.adminPGDatabase | quote }}
        - name: MAX_THREAD_LIFESPAN
          value: {{ .Values.livenessProbe.maxThreadLifespan | quote }}
{{- if eq .Values.readinessProbe.enabled true }}
        readinessProbe:
            exec:
              command:
                - "/opt/opentext/container_files/bash/check_cs_readiness.sh"
            initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
            timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
            periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
{{- end }}
{{- if eq .Values.livenessProbe.enabled true }}
        livenessProbe:
            exec:
              command:
                - "/opt/opentext/container_files/bash/check_cs_liveness.sh"
            initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
            timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
            periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
            failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
{{- end }}
{{- if eq .pod_type "admin" }}
    {{- if eq .Values.contentServerAdmin.resources.enabled true }}
        resources:
          limits:
            cpu: {{ .Values.contentServerAdmin.resources.limits.cpu }}
            memory: {{ .Values.contentServerAdmin.resources.limits.memory }}
          requests:
            cpu: {{ .Values.contentServerAdmin.resources.requests.cpu }}
            memory: {{ .Values.contentServerAdmin.resources.requests.memory }}
    {{- end }}
{{- else if eq .pod_type "frontend" }}
    {{- if eq .Values.contentServerFrontend.resources.enabled true }}
        resources:
          limits:
            cpu: {{ .Values.contentServerFrontend.resources.limits.cpu }}
            memory: {{ .Values.contentServerFrontend.resources.limits.memory }}
          requests:
            cpu: {{ .Values.contentServerFrontend.resources.requests.cpu }}
            memory: {{ .Values.contentServerFrontend.resources.requests.memory }}
    {{- end }}
{{- else if eq .pod_type "backend-search" }}
    {{- if eq .Values.contentServerBackendSearch.resources.enabled true }}
        resources:
          limits:
            cpu: {{ .Values.contentServerBackendSearch.resources.limits.cpu }}
            memory: {{ .Values.contentServerBackendSearch.resources.limits.memory }}
          requests:
            cpu: {{ .Values.contentServerBackendSearch.resources.requests.cpu }}
            memory: {{ .Values.contentServerBackendSearch.resources.requests.memory }}
    {{- end }}
{{- else }}
    {{- printf "Unsupported pod_type of %s" .pod_type }}
    {{- fail }}
{{- end }}
        ports:
        # Content Server ports:
        - containerPort: 2099
        {{- if or (eq .pod_type "admin") (eq .pod_type "backend-search") }}
        # admin-server
        - containerPort: 5858
        {{- end }}
        # Tomcat port:
        - containerPort: 8080
        volumeMounts:
        - mountPath: "/opt/opentext/customization"
          name: customization-volume-mount
        - mountPath: "/opt/opentext/cs_persist"
          name: cs-persist
        - mountPath: "/opt/opentext/cs/logs"
          name: logs
        - mountPath: "/opt/opentext/container_files/custom_config/config.yaml"
          name: config
          subPath: config.yaml
        - name: secrets
          mountPath: "/opt/opentext/cs_persist/secrets"
        {{- if or (eq .pod_type "admin") (eq .pod_type "backend-search") }}
        {{- if not (or (eq .Values.config.search.localSearch.enabled true) (eq .Values.config.search.sharedSearch.enabled true))}}
          {{- fail "You must enable at least one of .Values.config.search.localSearch.enabled or .Values.config.search.sharedSearch.enabled" }}
        {{- end }}
        {{- if eq .Values.config.search.localSearch.enabled true }}
        - mountPath: "/opt/opentext/cs_index"
          name: {{ .Chart.Name }}-admin-index
        {{- end }}
        {{- if eq .Values.config.search.sharedSearch.enabled true }}
        - mountPath: "/opt/opentext/cs_index_shared"
          name: {{ .Chart.Name }}-admin-index-shared
        {{- end }}
        {{- end }}
{{- if eq .Values.config.documentStorage.type "efs" }}
        - mountPath: {{ .Values.config.documentStorage.efsPath | quote }}
          name: {{ .Chart.Name }}-efs
{{- end }}
{{- if (eq .Values.config.documentStorage.type "otac") }}
        - mountPath: "/opt/opentext/container_files/custom_config/{{ .Values.config.otac.certFilename }}"
          name: {{ .Chart.Name }}-ac-cert-configmap
          subPath: {{ .Values.config.otac.certFilename }}
{{- else if (eq .Values.config.documentStorage.type "otacc") }}
        - mountPath: "/opt/opentext/container_files/custom_config/{{ .Values.config.otac.certFilename }}"
          name: {{ .Chart.Name }}-ac-cert-configmap
          subPath: {{ .Values.config.otac.certFilename }}
{{- end }}
{{- if eq .Values.loadAdminSettings.enabled true }}
        # This is an XML file containing admin settings to be
        # applied to Content Server on first container start. There is a
        # corresponding configmap with the name
        # '{{ .Chart.Name }}-adminsettings-configmap' in the file otcs-configmaps.yaml
        - mountPath: "/opt/opentext/container_files/custom_config/{{ .Values.loadAdminSettings.filename }}"
          name: {{ .Chart.Name }}-adminsettings-configmap
          subPath: {{ .Values.loadAdminSettings.filename }}
{{- end }}
{{- if eq .Values.loadLicense.enabled true }}
        # This is an XML file containing a Content Server license to be
        # applied to Content Server on first container start.
        - mountPath: "/opt/opentext/container_files/custom_config/{{ .Values.loadLicense.filename }}"
          name: {{ .Chart.Name }}-license-configmap
          subPath: {{ .Values.loadLicense.filename }}
{{- end }}
{{- if eq .Values.config.database.oracle.loadTnsnames.enabled true }}
        - mountPath: "/opt/oracle/tnsnames.ora"
          name: {{ .Chart.Name }}-tnsnames-configmap
          subPath: {{ .Values.config.database.oracle.loadTnsnames.filename }}
{{- end }}
        securityContext:
          allowPrivilegeEscalation: false
      volumes:
        - name: customization-volume-mount
          emptyDir: {}
        - name: config
          configMap:
{{- if eq .pod_type "admin" }}
            name: {{ .Chart.Name }}-admin-configmap
{{- else if eq .pod_type "frontend" }}
            name: {{ .Chart.Name }}-frontend-configmap
{{- else if eq .pod_type "backend-search" }}
            name: {{ .Chart.Name }}-backend-search-configmap
{{- else }}
           {{- printf "Unsupported pod_type of %s" .pod_type }}
           {{- fail }}
{{- end }}
        - name: secrets
          secret:
            {{- if .Values.existingSecret }}
            secretName: {{ .Values.existingSecret }}
            {{- else }}
            secretName: {{ .Chart.Name }}-secrets
            {{- end }}
            # various secret keys are mounted to different sub paths as required by Content Server
            items:
            - key: DATA_ENCRYPTION_KEY
              path: key.bin
            - key: ADMIN_USER_PASSWORD
              path: ContentServer/local/general/AdminPwd
            - key: ADMIN_USER_PASSWORD
              path: AdminServer/local/Admin
            {{- range untilStep 1 ((add (.Values.contentServerBackendSearch.replicas) 2) | int) 1}}
            - key: ADMIN_USER_PASSWORD
            {{- if lt . 10 }}
              path: ContentServer/global/AdminServerPassword/AdminServer-0{{ . }}
            {{- else }}
              path: ContentServer/global/AdminServerPassword/AdminServer-{{ . }}
            {{- end }}
            {{- end }}
            - key: ADMIN_USER_PASSWORD
              path: AdminServer/local/Admin
            - key: DB_PASSWORD
              path: ContentServer/local/dbconnection_cs/password
            - key: DB_ADMIN_PASSWORD
              path: ContentServer/local/db_admin_password
{{- if eq .Values.config.createBizadminUser true }}
            - key: BIZ_ADMIN_PASSWORD
              path: ContentServer/local/biz_admin_password
{{- end }}
{{- if eq .Values.config.createAppMonitorUser true }}
            - key: APPMONITOR_PASSWORD
              path: ContentServer/local/appmonitor_password
{{- end }}
{{- if eq .Values.config.deployBusinessScenarios true }}
            - key: SCENARIO_OWNER_PASSWORD
              path: ContentServer/local/scenario_owner_password
{{- end }}
{{- if eq .Values.config.documentStorage.type "otacc" }}
            - key: AC_CORE_PASSWORD
              path: ContentServer/local/ac_core_password
{{- end }}
{{- if or (eq .Values.config.documentStorage.type "otac") (eq .Values.config.documentStorage.type "otacc") }}
        # Used for Archive Center certificate file:
        - name: {{ .Chart.Name }}-ac-cert-configmap
          configMap:
            name: {{ .Chart.Name }}-ac-cert-configmap
{{- end }}
{{- if eq .Values.loadLicense.enabled true }}
        # Used for Content Server license
        - name: {{ .Chart.Name }}-license-configmap
          configMap:
            name: {{ .Chart.Name }}-license-configmap
{{- end }}
{{- if eq .Values.config.database.oracle.loadTnsnames.enabled true }}
        # Used for oracle tnsnames.ora
        - name: {{ .Chart.Name }}-tnsnames-configmap
          configMap:
            name: {{ .Chart.Name }}-tnsnames-configmap
{{- end }}
{{- if eq .Values.loadAdminSettings.enabled true }}
        # Used for custom admin settings (llconfig):
        - name: {{ .Chart.Name }}-adminsettings-configmap
          configMap:
            name: {{ .Chart.Name }}-adminsettings-configmap
{{- end }}
{{- if eq .Values.config.search.sharedSearch.enabled true }}
        - name: {{ .Chart.Name }}-admin-index-shared
          persistentVolumeClaim:
            claimName: {{ .Chart.Name }}-admin-index-shared
{{- end }}
{{- if eq .Values.config.documentStorage.type "efs" }}
        # Used for shared EFS (External File System for Document Storage):
        - name: {{ .Chart.Name }}-efs
          persistentVolumeClaim:
            claimName: {{ .Chart.Name }}-efs
{{- end }}
{{- if eq .Values.fluentbit.enabled true }}
        - name: fluentbit-config
          configMap:
            name: {{ .Chart.Name }}-fluentbit-configmap
            items:
            - key: fluent-bit.conf
              path: fluent-bit.conf
            - key: cs-parsers.conf
              path: cs-parsers.conf
            - key: security-logs-filter.conf
              path: security-logs-filter.conf
            - key: include.conf
              path: include.conf
{{- end }}
{{- if .Values.image.pullSecret }}
      imagePullSecrets:
      - name: {{ .Values.image.pullSecret }}
{{- end }}
  volumeClaimTemplates:
  - metadata:
      name: cs-persist
      {{- if .Values.pvc.csPersist.labels }}
      labels:
        {{- range .Values.pvc.csPersist.labels }}
        {{ . }}
        {{- end }}
      {{- end }}
    spec:
      accessModes:
        - ReadWriteOnce
{{- if .Values.storageClassName }}
      storageClassName: {{ .Values.storageClassName | quote }}
{{- end }}
      resources:
        requests:
          storage: {{ .Values.csPersist.storage }}
  - metadata:
      name: logs
      {{- if .Values.pvc.logs.labels }}
      labels:
        {{- range .Values.pvc.logs.labels }}
        {{ . }}
        {{- end }}
      {{- end }}
    spec:
      accessModes:
        - ReadWriteOnce
{{- if .Values.storageClassName }}
      storageClassName: {{ .Values.storageClassName | quote }}
{{- end }}
      resources:
        requests:
          storage: {{ .Values.csPersist.logStorage }}
{{- if or (eq .pod_type "admin") (eq .pod_type "backend-search") }}
{{- if eq .Values.config.search.localSearch.enabled true }}
  - metadata:
      name: {{ .Chart.Name }}-admin-index
    spec:
      accessModes:
        - ReadWriteOnce
{{- if .Values.storageClassName }}
      storageClassName: {{ .Values.storageClassName | quote }}
{{- end }}
      resources:
        requests:
          storage: {{ .Values.config.search.localSearch.storage }}
{{- end }}
{{- end }}
---
{{- end }}
