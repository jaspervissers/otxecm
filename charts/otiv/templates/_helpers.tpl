{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "brava.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "brava.fullname" -}}
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
{{- define "brava.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Base Name used for naming most resources
*/}}
{{- define "base.resource.name" -}}
otiv-{{ .Chart.Name }}
{{- end -}}

{{/*
OTDS Ingress FQDN
*/}}
{{- define "otds.fqdn" -}}
{{ regexReplaceAllLiteral "^http(s?)://" ( include "otds.public.url" . ) "" | regexFind "[^:]+" | required "A valid .Values.global.otdsPublicUrl value with http(s)://domain is required" }}
{{- end -}}

{{/*
OTDS External URL path
*/}}
{{- define "otds.public.url" -}}
{{- if .Values.global.otdsPublicUrl -}}
{{- if not (regexFind "^http(s?)://" .Values.global.otdsPublicUrl ) -}}
{{- fail "A valid .Values.global.otdsPublicUrl value with http(s)://domain is required" -}}
{{- end -}}
{{ .Values.global.otdsPublicUrl }}
{{- else -}}
{{ .Values.global.otdsWebProtocol }}://otds{{ template "ingress.suffix" .}}
{{- end -}}
{{- end -}}

{{/*
OTDS Service Name
*/}}
{{- define "otds.service.name" -}}
{{- if .Values.global.otds.otdsUseReleaseName }}
{{- printf "%s-%s" .Release.Name .Values.global.otds.otdsws.serviceName -}}
{{- else }}
{{- printf "%s" .Values.global.otds.otdsws.serviceName -}}
{{- end }}
{{- end -}}

{{/*
OTDS URL path
*/}}
{{- define "otds.url" -}}
{{- if .Values.global.otdsInCluster -}}
{{- if .Values.global.otdsPrivateUrl -}}
{{ .Values.global.otdsPrivateUrl }}
{{- else -}}
http://{{ template "otds.service.name" . }}
{{- end -}}
{{- else -}}
{{ template "otds.public.url" . }}
{{- end -}}
{{- end -}}

{{/*
OTDS API URL path
*/}}
{{- define "otds.api.url" -}}
{{ template "otds.url" . }}/otdsws
{{- end -}}

{{/*
OTDS Ingress URL path
*/}}
{{- define "otds.admin.url" -}}
{{ template "otds.public.url" . }}/otds-admin
{{- end -}}

{{/*
Image source path for the init-otds image including repo and tag
*/}}
{{- define "otds.init.image.path" -}}
{{ trimSuffix "/" .Values.global.imageSource }}/{{ .Values.global.otdsInit.image.name }}:{{ .Values.global.otdsInit.image.tag }}
{{- end -}}

{{/*
Image source path including repo and tag
*/}}
{{- define "image.source.path" -}}
{{- $imageSource := default .Values.global.imageSource .Values.image.source | trimSuffix "/" -}}
{{ printf "%s/%s" $imageSource .Values.image.name }}:{{ .Values.image.tag }}
{{- end -}}

{{/*
Image pull policy
*/}}
{{- define "image.pull.policy" -}}
{{- if .Values.image -}}
{{ default .Values.global.imagePullPolicy .Values.image.pullPolicy }}
{{- else -}}
{{ .Values.global.imagePullPolicy }}
{{- end -}}
{{- end -}}

{{/*
The version
*/}}
{{- define "version.stamp" -}}
{{- if .Values.image.tag -}}
{{- .Values.image.tag -}}
{{- else -}}
{{- now | printf "%s" | trunc 19 -}}
{{- end -}}
{{- end -}}

{{- define "ingress.suffix" -}}
{{- if .Values.global.ingressIncludeNamespace -}}
-{{ .Release.Namespace }}.{{ .Values.global.ingressDomainName }}
{{- else -}}
.{{ .Values.global.ingressDomainName }}
{{- end -}}
{{- end -}}

{{/*
Ingress URL path
*/}}
{{- define "ingress.fqdn" -}}
{{ template "base.resource.name" . }}{{ template "ingress.suffix" .}}
{{- end -}}

{{/*
Outputs the yaml that extracts the secret for the service, plus the name of the env vars.
Placed within the env section of the deployment descriptor.
The argument is the service name, i.e. "publication"
*/}}
{{- define "env.secrets" -}}
          - name: AUTH_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: otiv-{{ . }}-secrets
                key: authId
          - name: AUTH_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: otiv-{{ . }}-secrets
                key: authSecret
{{- end -}}

{{- define "init.otds.container" -}}
      - name: init-otds
        image: {{ include "otds.init.image.path" . }}
        imagePullPolicy: {{ include "image.pull.policy" . }}
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 1000
          runAsGroup: 1000
        env:
        - name: SERVICE_ID
          value: {{ .Chart.Name }}
        - name: OTDS_ORIGIN
          value: {{ template "otds.api.url" .}}
        - name: OTDS_PWD
          valueFrom:
            secretKeyRef:
              name: {{ .Values.global.otdsSecretName }}
              key:  {{ .Values.global.otdsSecretKey }}
{{- $dbCharts := dict "config" "y" "publication" "y" "publisher" "y" "markup" "y" "otiv" "y" }}
{{- if hasKey $dbCharts .Chart.Name }}
        - name: PITHOS_HOST
          value:  {{ .Values.global.database.hostname }}
        - name: PITHOS_PORT
          value:  '{{ .Values.global.database.port }}'
        - name: PITHOS_DB
          value:  {{ .Values.global.database.ivName }}
        - name: PITHOS_USER
          value:  {{ .Values.global.database.adminUsername }}
        - name: PITHOS_PSQL_DB
          value:  {{ .Values.global.database.adminDatabase }}
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Values.global.dbSecretName }}
              key:  {{ .Values.global.dbSecretKey }}
{{- end }}
{{- if .Values.writeMarkups }}
        - name: WRITE_MARKUPS
          value: '{{ .Values.writeMarkups }}'
{{- end }}
{{- if .Values.useBasicLicense }}
        - name: BASIC_LICENSE
          value: 'True'
{{- end }}
{{- if .Values.global.resourceName }}
        - name: RESOURCE_NAME
          value: {{ .Values.global.resourceName }}
{{- end }}
{{- if .Values.global.resourceGuid }}
        - name: RESOURCE_GUID
          value: '{{ .Values.global.resourceGuid }}'
{{- end }}
{{- if .Values.global.timeZone }}
        - name: TZ
          value: '{{ .Values.global.timeZone }}'
{{- end }}
{{- if .Values.global.usingServiceMesh }}
        - name: WRITE_MARKUPS
          value: 'True'
        command:
          - bash
          - -c
          - |
            sleep 2;
{{- if not .Values.global.skipIstioSidecarCalls }}
            until curl -fsI http://localhost:15021/healthz/ready; do echo Waiting for Sidecar...; sleep 3; done;
{{- end }}
            python ivAddOauthAndLicense.py;
{{- if not .Values.global.skipIstioSidecarCalls }}
            x=$(echo $?); curl -fsI -X POST http://localhost:15020/quitquitquit && exit $x
{{- end }}
{{- end }}
{{- end -}}

{{/*
Outputs the yaml that sets the env var for the postresql password
*/}}
{{- define "pg.env.password" -}}
          - name: {{ default "PITHOS_PWD" .pwdKey }}
            valueFrom:
              secretKeyRef:
                name: {{ .global.dbSecretName }}
                key:  {{ .global.dbSecretKey }}
{{- end -}}

{{/*
Outputs the yaml that sets the env var for the rabbitmq password
*/}}
{{- define "rb.env.password" -}}
          - name: AJIRA_PWD
            valueFrom:
              secretKeyRef:
                name: {{ .global.msgHost }}
                key: rabbitmq-password
{{- end -}}

{{/*
Outputs the yaml that sets the env vars for the postgresql and rabbitmq passwords
*/}}
{{- define "pg.rb.env.passwords" -}}
          {{ template "pg.env.password" . }}
          {{ template "rb.env.password" . }}
{{- end -}}


{{/*
Calcs checksum value based on the configmap and secret for passed in sub-chart
*/}}
{{- define "config.secret.checksum" -}}
{{- $configChecksum := include (print $.Template.BasePath "/configMap.yaml") . | sha256sum -}}
{{- printf "%s-%s" $configChecksum -}}
{{- end -}}


{{/*
Returns true if http is allowed protocol, else false
*/}}
{{- define "http.allowed" -}}
{{- if eq .Values.global.publicWebProtocol "http" -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "timezone" -}}
{{- if .Values.global.timeZone }}
    TZ: {{ .Values.global.timeZone }}
{{- end -}}
{{- end -}}

{{- define "cors.config" -}}
    ENFORCE_CORS_ORIGINS: '{{ hasKey .Values "enforceCorsOrigins" | ternary .Values.enforceCorsOrigins .Values.global.enforceCorsOrigins }}'
{{- if or .Values.global.corsOriginsList .Values.corsOriginsList }}
    CORS_ORIGINS_LIST: {{ default .Values.global.corsOriginsList .Values.corsOriginsList }}
{{- end }}
{{- if or .Values.global.corsOriginsRegex .Values.corsOriginsRegex }}
    CORS_ORIGINS_REGEX: '{{ default .Values.global.corsOriginsRegex .Values.corsOriginsRegex }}'
{{- end }}
{{- end }}

{{- define "forwarded.config" -}}
    ENFORCE_FORWARDED_HOSTS: '{{ hasKey .Values "enforceForwardedHosts" | ternary .Values.enforceForwardedHosts .Values.global.enforceForwardedHosts }}'
{{- if or .Values.global.forwardedHostsList .Values.forwardedHostsList }}
    FORWARDED_HOSTS_LIST: {{ default .Values.global.forwardedHostsList .Values.forwardedHostsList }}
{{- end }}
{{- if or .Values.global.forwardedHostsRegex .Values.forwardedHostsRegex }}
    FORWARDED_HOSTS_REGEX: '{{ default .Values.global.forwardedHostsRegex .Values.forwardedHostsRegex }}'
{{- end }}
{{- end }}

{{- define "new.relic.transform.config" -}}
{{- if and .Values.global.newRelic.licenseKey .Values.global.newRelic.host }}
    RUNTIME_ENVIRONMENT: cfcr-iv
{{- if .Values.global.newRelic.baseAppName }}
    NEWRELIC_APP_NAME: {{ include "base.resource.name" . }}-{{ .Release.Namespace }}.{{ .Values.global.newRelic.baseAppName }}
{{- else }}
    NEWRELIC_APP_NAME: {{ include "base.resource.name" . }}-{{ .Release.Namespace }}.{{ .Values.global.ingressDomainName }}
{{- end }}
    NEWRELIC_KEY: {{ .Values.global.newRelic.licenseKey }}
    NEWRELIC_HOST: {{ .Values.global.newRelic.host }}
    NEWRELIC_PORT: '{{ .Values.global.newRelic.port }}'
{{- end }}
{{- end }}

{{- define "new.relic.viewing.config" -}}
{{- if and .Values.global.newRelic.licenseKey .Values.global.newRelic.host }}
{{- if .Values.global.newRelic.baseAppName }}
    NEW_RELIC_APP_NAME: {{ include "base.resource.name" . }}-{{ .Release.Namespace }}.{{ .Values.global.newRelic.baseAppName }}
{{- else }}
    NEW_RELIC_APP_NAME: {{ include "base.resource.name" . }}-{{ .Release.Namespace }}.{{ .Values.global.ingressDomainName }}
{{- end }}
    NEW_RELIC_LICENSE_KEY: {{ .Values.global.newRelic.licenseKey }}
    NEW_RELIC_LOG_LEVEL: {{ .Values.newRelic.loglevel }}
    NEW_RELIC_PROXY_URL: http://{{ .Values.global.newRelic.host }}:{{ .Values.global.newRelic.port }}
{{- end }}
{{- end }}

{{- define "proxy.url.params" -}}
{{- if and .Values.global.proxy.host .Values.global.proxy.port }}
    http_proxy:  http://{{ .Values.global.proxy.host }}:{{ .Values.global.proxy.port }}
    https_proxy: http://{{ .Values.global.proxy.host }}:{{ .Values.global.proxy.port }}
    no_proxy: '{{ .Values.global.proxy.excludes | replace "|" "," }}'
{{- end }}
{{- end }}

{{- define "proxy.params" -}}
{{- if .Values.global.proxy.host }}
    PROXY_HOST: {{ .Values.global.proxy.host }}
    PROXY_PORT: '{{ .Values.global.proxy.port }}'
    no_proxy: '{{ .Values.global.proxy.excludes | replace "," "|" }}'
{{- end }}
{{- end }}

{{- define "trusted.source.origins" -}}
{{- if .Values.global.trustedSourceOrigins }}
    TRUSTED_SOURCE_ORIGINS: {{ .Values.global.trustedSourceOrigins }}
{{- end }}
{{- if .Values.global.trustedSourceOriginsAnonymous }}
    TRUSTED_SOURCE_ORIGINS_ANONYMOUS: {{ .Values.global.trustedSourceOriginsAnonymous }}
{{- end }}
{{- end }}

{{/*
Additional labels for otiv pods
*/}}
{{- define "otiv.custom.labels" -}}
{{- if .Values.podLabels }}
{{- toYaml .Values.podLabels | trim | nindent 8 }}
{{- end }}
{{- if .Values.global.otivPodLabels }}
{{- toYaml .Values.global.otivPodLabels | trim | nindent 8 }}
{{- end }}
{{- end }}
