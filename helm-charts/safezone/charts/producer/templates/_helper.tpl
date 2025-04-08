{{/*
Shared helpers for SafeZone umbrella chart
*/}}

{{- define "safezone.name" -}}
safezone
{{- end }}

{{- define "safezone.fullname" -}}
{{ .Release.Name }}-{{ include "safezone.name" . }}
{{- end }}

{{- define "producer.version" -}}
{{ .Chart.version }}
{{- end }}

{{- define "producer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "safezone.name" . }}-{{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "producer.simulator.svcname" -}}
{{ .Release.Name }}-producer-covid-simulator
{{- end }}

{{- define "producer.ingestor.svcname" -}}
{{ .Release.Name }}-producer-covid-ingestor
{{- end }}