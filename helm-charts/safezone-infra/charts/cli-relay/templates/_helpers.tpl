{{/* helpers for SafeZone infra umbrella chart */}}

{{- define "fullname" -}}
{{- if .Values.fullnameOverride -}}
{{ .Values.fullnameOverride }}
{{- else -}}
safezone
{{- end -}}
{{- end }}

{{- define "safezone.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "safezone.svc.postfix" -}}
{{ .Release.Namespace }}.svc.cluster.local
{{- end }}

{{/* Service name pre-define */}}

{{/* CLI Relay */}}

{{- define "safezone.cliRelay.port" -}}
8000
{{- end }}

{{- define "safezone.cliRelay.basename" -}}
{{ include "fullname" . }}-cli-relay
{{- end }}


{{- define "safezone.cliRelay.url" -}}
http://{{ include "safezone.cliRelay.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.cliRelay.port" . }}
{{- end }}

{{/* Pandemic Simulator */}}

{{- define "safezone.pandemicSimulator.port" -}}
8000
{{- end }}

{{- define "safezone.pandemicSimulator.basename" -}}
{{ include "fullname" . }}-pandemic-simulator
{{- end }}


{{- define "safezone.pandemicSimulator.url" -}}
http://{{ include "safezone.pandemicSimulator.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.pandemicSimulator.port" . }}
{{- end }}


{{/* Ingestor */}}

{{- define "safezone.ingestor.port" -}}
8000
{{- end }}

{{- define "safezone.ingestor.basename" -}}
{{ include "fullname" . }}-ingestor
{{- end }}

{{- define "safezone.ingestor.url" -}}
http://{{ include "safezone.ingestor.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.ingestor.port" . }}
{{- end }}


{{/* Worker */}}

{{- define "safezone.worker.basename" -}}
{{ include "fullname" . }}-worker
{{- end }}

{{/* Analytics API */}}

{{- define "safezone.analyticsAPI.port" -}}
8000
{{- end }}

{{- define "safezone.analyticsAPI.basename" -}}
{{ include "fullname" . }}-analytics-api
{{- end }}

{{- define "safezone.analyticsAPI.url" -}}
http://{{ include "safezone.analyticsAPI.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.analyticsAPI.port" . }}
{{- end }}


{{/* Dashboard */}}

{{- define "safezone.dashboard.port" -}}
8080
{{- end }}

{{- define "safezone.dashboard.basename" -}}
{{ include "fullname" . }}-dashboard
{{- end }}

{{- define "safezone.dashboard.url" -}}
http://{{ include "safezone.dashboard.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.dashboard.port" . }}
{{- end }}

{{/* Cache Redis */}}

{{- define "safezone.redisCache.port" -}}
6379
{{- end }}

{{- define "safezone.redisCache.basename" -}}
{{ include "fullname" . }}-redis-cache-master 
{{- end }}

{{- define "safezone.redisCache.host" -}}
{{ include "safezone.redisCache.basename" . }}.{{include "safezone.svc.postfix" . }}
{{- end }}

{{/* Time Server */}}

{{- define "safezone.timeServer.port" -}}
8000
{{- end }}

{{- define "safezone.timeServer.basename" -}}
{{ include "fullname" . }}-time-server
{{- end }}

{{- define "safezone.timeServer.url" -}}
http://{{ include "safezone.timeServer.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.timeServer.port" . }}
{{- end }}


{{/* Mkdoc */}}

{{- define "safezone.mkdoc.port" -}}
8080
{{- end }}

{{- define "safezone.mkdoc.basename" -}}
{{ include "fullname" . }}-mkdoc
{{- end }}

{{- define "safezone.mkdoc.url" -}}
http://{{ include "safezone.mkdoc.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.mkdoc.port" . }}
{{- end }}
