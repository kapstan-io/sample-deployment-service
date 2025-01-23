{{/*
Expand the name of the chart.
*/}}
{{- define "sample-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sample-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sample-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sample-service.labels" -}}
helm.sh/chart: {{ include "sample-service.chart" . }}
{{ include "sample-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sample-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sample-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sample-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sample-service.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the image pull secret json to use
*/}}
{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/* Configuration Secrets */}}
{{- define "confvars" -}}
{{- $files := .Files }}
{{- range $idx, $entry := .Values.env }}
{{- if eq $entry.type "secret" }}
{{ $entry.name }}: {{ $entry.value | b64enc }}
{{- else if eq $entry.type "secretEncoded" }}
{{ $entry.name }}: {{ $entry.value }}
{{- else if eq $entry.type "secretFile" }}
{{ $entry.name }}: {{ ($files.Get $entry.dataPath) | b64enc }}
{{- end }}
{{- end }}
{{- end }}

{{/* Environment Variables */}}
{{- define "environment" -}}
{{- range $idx, $entry := .Values.env }}
- name: {{ $entry.name }}
{{- if eq $entry.type "secret" }}
  valueFrom:
    secretKeyRef:
      name: {{ include "sample-service.fullname" $ }}-confvars
      key: {{ $entry.name }}
{{- else if or (eq $entry.type "secretFile") (eq $entry.type "secretEncoded") }}
  value: {{ printf "/confvars/%s" ($entry.name | lower) | quote }}
{{- else if eq $entry.type "certificate" }}
  {{-  if eq $entry.mountAs "environmentVariable" }}
  valueFrom:
    secretKeyRef:
      name: {{ include "sample-service.fullname" $ }}-certificates-{{ $entry.reference}}
      key: {{ $entry.subtype }}
  {{- else if eq $entry.mountAs "filePath" }}
  value: {{ printf "/confvars-certs/%s-%s" ($entry.reference| lower) ($entry.subtype| lower) | quote }}
  {{- end }}
{{- else }}
  value: {{ $entry.value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/* Secret File Volumes */}}
{{- define "secretFileVolumes" -}}
- name: {{ include "sample-service.fullname" $}}-confvars
  secret:
    secretName: {{ include "sample-service.fullname" $}}-confvars
    items:
    {{- range $idx, $entry := .Values.env }}
    {{- if or (eq $entry.type "secretFile") (eq $entry.type "secretEncoded")}}
    - key: {{ $entry.name }}
      path: {{ $entry.name | lower }}
{{- end }}
{{- end }}
{{- end }}

{{/* Certificate Volumes */}}
{{- define "certificateVolumes" -}}
{{- if .Values.generateCertificates }}
- name: {{ include "sample-service.fullname" $}}-certificates
  projected:
    sources:
       {{- range $idx, $cert := .Values.certificates }}
    - secret:
        name: {{ include "sample-service.fullname" $}}-{{ $cert.name }}-certificate
        items:
        - key: ca.crt
          path: {{ $cert.name | lower }}-ca.crt
        - key: tls.crt
          path: {{ $cert.name | lower }}-tls.crt
        - key: tls.key
          path: {{ $cert.name | lower }}-tls.key
{{- end }}
{{- end }}
{{- end }}
