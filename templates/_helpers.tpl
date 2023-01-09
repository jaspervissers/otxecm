{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "otxecm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "otxecm.fullname" -}}
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
{{- define "otxecm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "otxecm.labels" -}}
app.kubernetes.io/name: {{ include "otxecm.name" . }}
helm.sh/chart: {{ include "otxecm.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Determine the otds service name depending on whether a custom value has been used for these values:
global.otdsUseReleaseName
global.otds.otdsws.serviceName
*/}}
{{- define "otxecm.otdsServiceName" -}}
{{- if .Values.global.otds.otdsUseReleaseName }}
{{- printf "%s-%s" .Release.Name .Values.global.otds.otdsws.serviceName | quote -}}
{{- else }}
{{- printf "%s" .Values.global.otds.otdsws.serviceName | quote -}}
{{- end }}
{{- end -}}

{{/*
OTIV Ingress Suffix
*/}}
{{- define "otiv.ingress.suffix" -}}
{{- if .Values.global.ingressIncludeNamespace -}}
-{{ .Release.Namespace }}.{{ .Values.global.ingressDomainName }}
{{- else -}}
.{{ .Values.global.ingressDomainName }}
{{- end -}}
{{- end -}}

{{/*
Determine Pre Upgrade Job image tag
*/}}
{{- define "pre.upgrade.job.image.tag" -}}
{{- if .Values.preUpgradeJob.image.tag -}}
{{ .Values.preUpgradeJob.image.tag }}
{{- else -}}
{{- if eq .Values.preUpgradeJob.image.name "bitnami/kubectl" -}}
{{ .Capabilities.KubeVersion.Major }}.{{ mustRegexReplaceAll "[\\+]{1}[0-9]*" .Capabilities.KubeVersion.Minor "" }}
{{- else -}}
latest
{{- end -}}
{{- end -}}
{{- end -}}
