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

{{- define "safezone.core.api.svcname" -}}
{{ .Release.Name }}-consumer-analytics-api
{{- end}}

{{- define "safezone.core.api.url" -}}
http://{{- include "safezone.core.api.svcname" . }}:{{ .Values.consumer.analyticsAPI.service.port }}
{{- end }}

{{- define "safezone.ui.dashboard.svcname" -}}
{{ .Release.Name }}-consumer-dashboard
{{- end}}

{{- define "safezone.ui.dashboard.url" -}}
http://{{- include "safezone.core.dashboard.svcname" . }}:{{ .Values.consumer.dashboard.service.port }}
{{- end }}

{{- define "safezone.core.simulator.svcname" -}}
{{ .Release.Name }}-producer-simulator
{{- end}}

{{- define "safezone.core.simulator.url" -}}
http://{{- include "safezone.core.simulator.svcname" . }}:{{ .Values.producer.simulator.service.port }}
{{- end }}

{{- define "safezone.core.ingestor.svcname" -}}
{{ .Release.Name }}-producer-ingestor
{{- end}}

{{- define "safezone.core.ingestor.url" -}}
http://{{- include "safezone.core.ingestor.svcname" . }}:{{ .Values.producer.ingestor.service.port }}
{{- end }}

{{- define "safezone.infra.cliRelay.svcname" -}}
{{ .Release.Name }}-addons-cli-relay
{{- end }}

{{- define "safezone.infra.cliRelay.url" -}}
http://{{- include "safezone.infra.cliRelay.svcname" . }}:{{ .Values.cliRelay.service.port }}
{{- end }}

{{- define "safezone.infra.redis.svcname" -}}
{{ .Release.Name }}-addons-redis
{{- end }}

{{- define "safezone.infra.redis.url" -}}
http://{{- include "safezone.infra.redis.svcname" . }}:{{ .Values.redis.service.port }}
{{- end }}