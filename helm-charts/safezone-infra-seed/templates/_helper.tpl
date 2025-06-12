{{/* helpers for SafeZone infra umbrella chart */}}

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

{{- define "safezone.domain" -}}
safezone
{{- end }}

{{/* helpers.tpl - SafeZone default ports / constants */}}

{{- define "safezone.cliRelay.port" -}}
8000
{{- end }}

{{- define "safezone.cliRelay.svcname" -}}
safezone-cli-relay
{{- end }}

{{- define "safezone.cliRelay.url" -}}
http://{{ include "safezone.cliRelay.svcname" . }}.{{ include "safezone.domain" . }}.svc.cluster.local:{{ include "safezone.cliRelay.port" . }}
{{- end }}

{{- define "safezone.simulator.port" -}}
8001
{{- end }}

{{- define "safezone.simulator.svcname" -}}
safezone-simulator
{{- end }}

{{- define "safezone.simulator.url" -}}
http://{{ include "safezone.simulator.svcname" . }}.{{ include "safezone.domain" . }}.svc.cluster.local:{{ include "safezone.simulator.port" . }}
{{- end }}

{{- define "safezone.ingestor.port" -}}
8002
{{- end }}

{{- define "safezone.ingestor.svcname" -}}
safezone-ingestor
{{- end }}

{{- define "safezone.ingestor.url" -}}
http://{{ include "safezone.ingestor.svcname" . }}.{{ include "safezone.domain" . }}.svc.cluster.local:{{ include "safezone.ingestor.port" . }}
{{- end }}

{{- define "safezone.analyticsAPI.port" -}}
8003
{{- end }}

{{- define "safezone.analyticsAPI.svcname" -}}
safezone-analytics-api
{{- end }}

{{- define "safezone.analyticsAPI.url" -}}
http://{{ include "safezone.analyticsAPI.svcname" . }}.{{ include "safezone.domain" . }}.svc.cluster.local:{{ include "safezone.analyticsAPI.port" . }}
{{- end }}

{{- define "safezone.dashboard.port" -}}
8004
{{- end }}

{{- define "safezone.dashboard.svcname" -}}
safezone-dashboard
{{- end }}

{{- define "safezone.dashboard.url" -}}
http://{{ include "safezone.dashboard.svcname" . }}.{{ include "safezone.domain" . }}.svc.cluster.local:{{ include "safezone.dashboard.port" . }}
{{- end }}

{{- define "safezone.redisSys.port" -}}
6379
{{- end }}

{{- define "safezone.redisSys.svcname" -}}
safezone-redis-sys-master
{{- end }}

{{- define "safezone.redisSys.accessible" -}}
{{ include "safezone.redisSys.svcname" . }}.{{ include "safezone.domain" . }}.svc.cluster.local:{{ include "safezone.redisSys.port" . }}
{{- end }}

{{- define "safezone.redisCache.port" -}}
6379
{{- end }}

{{- define "safezone.redisCache.svcname" -}}
safezone-redis-cache-master
{{- end }}

{{- define "safezone.redisCache.accessible" -}}
{{ include "safezone.redisCache.svcname" . }}.{{ include "safezone.domain" . }}.svc.cluster.local:{{ include "safezone.redisCache.port" . }}
{{- end }}
