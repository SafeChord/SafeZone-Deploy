{{/*
Shared helpers for SafeZone umbrella chart
*/}}

{{- define "safezone.name" -}}
safezone
{{- end }}

{{- define "safezone.fullname" -}}
{{ .Release.Name }}-{{ include "safezone.name" . }}
{{- end }}

{{- define "consumer.version" -}}
{{ .Chart.version }}
{{- end }}

{{- define "consumer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "safezone.name" . }}-{{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "consumer.api.svcname" -}}
{{ .Release.Name }}-consumer-analytics-api
{{- end }}

{{- define "consumer.dashboard.svcname" -}}
{{ .Release.Name }}-consumer-dashboard
{{- end }}