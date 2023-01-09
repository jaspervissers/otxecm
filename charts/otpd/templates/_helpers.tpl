{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "otpd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "otpd.fullname" -}}
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
{{- define "otpd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "otpd.labels" -}}
app.kubernetes.io/name: {{ include "otpd.name" . }}
helm.sh/chart: {{ include "otpd.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
  otpd.hostname uses publicHostname if ingress is enabled.
  If you are not using an ingress, it is set to empty.
*/}}
{{- define "otpd.hostname" }}
{{- if eq .Values.ingress.enabled true }}
  {{- printf .Values.publicHostname | required "A valid .Values.publicHostname value is required" }}
{{- else }}
  {{- printf "" }}
{{- end }}
{{- end }}

{{/*
  otpd.port uses port 80 for http, and 443 for https if your ingress has a secret.
  If you are not using an ingress, use 80.
*/}}
{{- define "otpd.port" }}
{{- if eq .Values.ingress.enabled true }}
  {{- if .Values.ingress.secret }}
    {{- printf "443" | quote }}
  {{- else }}
      {{- printf "80" | quote }}
  {{- end }}
{{- else }}
  {{- printf "80" | quote }}
{{- end }}
{{- end }}

{{/*
  otpd.protocol uses https if your ingress has a secret, http if it does not.
  If you are not using an ingress, use http.
*/}}
{{- define "otpd.protocol" }}
{{- if eq .Values.ingress.enabled true }}
  {{- if .Values.ingress.secret }}
    {{- printf "https" }}
  {{- else }}
      {{- printf "http" }}
  {{- end }}
{{- else }}
  {{- printf "http" }}
{{- end }}
{{- end }}

{{/*
  otpd.otcsEnabled uses true, if otcs available otherwise false
*/}}
{{- define "otpd.otcsEnabled" }}
  {{-  if eq .Values.otcs.enabled true }}
    {{- printf "true" | quote }}
  {{- else }}
    {{- printf "false" | quote }}
  {{- end }}
{{- end }}

{{/*
  otds.publicProtocol uses the protocol defined in otds.publicHostname.
  'http' is used in case of LoadBalancer sceario
*/}}
{{- define "otds.publicProtocol" }}
  {{- if ne .Values.otds.publicHostname "" }}
    {{- $publicProtocol := regexFind "^http(s?)" .Values.otds.publicHostname }}
    {{- printf $publicProtocol }}
  {{- else }}
    {{- printf "http" }}
  {{- end }}
{{- end }}

{{/*
  otds.publicPort uses the port defined in otds.publicHostname.
  If no port is provided, 80 will be used if public hostname uses http.
  443 will be used if public hostname uses https.
  80 is used in case of LoadBalancer sceario
*/}}
{{- define "otds.publicPort" }}
  {{- if ne .Values.otds.publicHostname "" }}
    {{- $publicProtocol := regexFind "^http(s?)" .Values.otds.publicHostname }}
    {{- if regexFind ":([0-9]+)" .Values.otds.publicHostname }}
      {{- $publicHostPort := regexFind ":([0-9]+)" .Values.otds.publicHostname }}
      {{- printf $publicHostPort | trimPrefix ":" | quote }}
    {{- else if eq $publicProtocol "http" }}
      {{- printf "80" | quote }}
    {{- else if eq $publicProtocol "https" }}
      {{- printf "443" | quote }}
    {{- end }}
  {{- else }}
    {{- printf "80" | quote }}
  {{- end }}
{{- end }}
