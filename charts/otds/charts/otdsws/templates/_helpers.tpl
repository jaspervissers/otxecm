{{/* vim: set filetype=mustache: */}}
{{/*
Determine the name depending on whether or not to use the release name.
*/}}
{{- define "otdsws.name" -}}
{{- if eq .Values.global.otdsUseReleaseName true }}
{{- printf "%s-%s" .Release.Name .Chart.Name -}}
{{- else }}
{{- printf "%s" .Chart.Name -}}
{{- end }}
{{- end -}}

{{/*
Determine the service name depending on whether or not to use the release name.
*/}}
{{- define "otdsws.service" -}}
{{- if eq .Values.global.otdsUseReleaseName true }}
{{- printf "%s-%s" .Release.Name .Values.serviceName -}}
{{- else }}
{{- printf "%s" .Values.serviceName -}}
{{- end }}
{{- end -}}

{{/*
Determine the DB url to use
*/}}
{{- define "otdsws.dburl" -}}
{{- printf "%s" .Values.otdsdb.url -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "otdsws.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "otdsws.labels" -}}
app.kubernetes.io/name: {{ include "otdsws.name" . }}
helm.sh/chart: {{ include "otdsws.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Determine Pre Upgrade Job image tag
*/}}
{{- define "preupgrade.job.image.tag" -}}
{{- if .Values.migration.preUpgradeJob.image.tag -}}
{{ .Values.migration.preUpgradeJob.image.tag }}
{{- else }}
latest
{{- end }}
{{- end -}}
