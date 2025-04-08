{{/*
Shared helpers for SafeZone umbrella chart
*/}}

{{- define "safezone.name" -}}
safezone
{{- end }}

{{- define "safezone.fullname" -}}
{{ .Release.Name }}-{{ include "safezone.name" . }}
{{- end }}

{{- define "cliRelay.version" -}}
{{ .Chart.version }}
{{- end }}

{{- define "cliRelay.selectorLabels" -}}
app.kubernetes.io/name: {{ include "safezone.name" . }}-{{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "cliRelay.svcname" -}}
{{ .Release.Name }}-addon-cli-relay
{{- end }}
