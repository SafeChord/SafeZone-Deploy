{{/*
Shared helpers for SafeZone umbrella chart
*/}}

{{- define "safezone.name" -}}
safezone
{{- end }}

{{- define "safezone.fullname" -}}
{{ .Release.Name }}-{{ include "safezone.name" . }}
{{- end }}

{{- define "safezone.version" -}}
{{ .Chart.AppVersion }}
{{- end }}

{{- define "safezone.selectorLabels" -}}
app.kubernetes.io/name: {{ include "safezone.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "safezone.ingressHost" -}}
{{ .Values.ingress.host }}
{{- end }}

{{/* Analytics API */}}
{{- define "safezone.consumer.api.svcname" -}}
{{ .Release.Name }}-consumer-analytics-api
{{- end}}

{{- define "safezone.consumer.api.url" -}}
http://{{- include safezone.consumer.api.svcname}}:{{ .Values.consumer.analyticsAPI.port }}
{{- end }}

{{/* Dashboard */}}
{{- define "safezone.consumer.dashboard.svcname" -}}
{{ .Release.Name }}-consumer-dashboard
{{- end}}

{{- define "safezone.consumer.dashboard.url" -}}
http://{{- include safezone.consumer.dashboard.svcname}}:{{ .Values.consumer.dashboard.port }}
{{- end }}

{{/* Simulator */}}
{{- define "safezone.producer.simulator.svcname" -}}
{{ .Release.Name }}-producer-simulator
{{- end}}

{{- define "safezone.producer.simulator.url" -}}
http://{{- include safezone.producer.simulator.svcname}}:{{ .Values.producer.simulator.port }}
{{- end }}

{{/* Ingestor */}}
{{- define "safezone.producer.ingestor.svcname" -}}
{{ .Release.Name }}-producer-ingestor
{{- end}}

{{- define "safezone.producer.ingestor.url" -}}
http://{{- include safezone.producer.ingestor.svcname}}:{{ .Values.producer.ingestor.port }}
{{- end }}

{{/* CLI Relay */}}
{{- define "safezone.addon.clirelay.svcname" -}}
{{ .Release.Name }}-addon-cli-relay
{{- end }}

{{- define "safezone.addon.clirelay.url" -}}
http://{{- include safezone.addon.clirelay.svcname}}:{{ .Values.addons.cli-relay.port }}
{{- end }}