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

{{- define "safezone.consumer.api.svcname" -}}
{{ .Release.Name }}-consumer-analytics-api
{{- end}}

{{- define "safezone.consumer.api.url" -}}
http://{{- include "safezone.consumer.api.svcname" . }}:{{ .Values.consumer.analyticsAPI.service.port }}
{{- end }}

{{- define "safezone.consumer.dashboard.svcname" -}}
{{ .Release.Name }}-consumer-dashboard
{{- end}}

{{- define "safezone.consumer.dashboard.url" -}}
http://{{- include "safezone.consumer.dashboard.svcname" . }}:{{ .Values.consumer.dashboard.service.port }}
{{- end }}

{{- define "safezone.producer.simulator.svcname" -}}
{{ .Release.Name }}-producer-simulator
{{- end}}

{{- define "safezone.producer.simulator.url" -}}
http://{{- include "safezone.producer.simulator.svcname" . }}:{{ .Values.producer.simulator.service.port }}
{{- end }}

{{- define "safezone.producer.ingestor.svcname" -}}
{{ .Release.Name }}-producer-ingestor
{{- end}}

{{- define "safezone.producer.ingestor.url" -}}
http://{{- include "safezone.producer.ingestor.svcname" . }}:{{ .Values.producer.ingestor.service.port }}
{{- end }}

{{- define "safezone.addons.cliRelay.svcname" -}}
{{ .Release.Name }}-addons-cli-relay
{{- end }}

{{- define "safezone.addons.cliRelay.url" -}}
http://{{- include "safezone.addons.cliRelay.svcname" . }}:{{ .Values.cliRelay.service.port }}
{{- end }}