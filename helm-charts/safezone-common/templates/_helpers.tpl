{{/* common helpers for SafeZone charts */}}

{{- define "fullname" -}}
{{ coalesce .Values.global.safezone.fullnameOverride "safezone" }}
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

{{/* Infra */}}

{{/* Time Server */}}

{{- define "safezone.timeServer.port" -}}
{{ default 8000 .Values.global.serviceDiscovery.timeServer.port }}
{{- end }}

{{- define "safezone.timeServer.basename" -}}
{{ include "fullname" . }}-{{ default "time-server" .Values.global.serviceDiscovery.timeServer.name }}
{{- end }}

{{- define "safezone.timeServer.url" -}}
http://{{ include "safezone.timeServer.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.timeServer.port" . }}
{{- end }}

{{/* CLI Relay */}}

{{- define "safezone.cliRelay.port" -}}
{{ default 8000 .Values.global.serviceDiscovery.cliRelay.port }}
{{- end }}

{{- define "safezone.cliRelay.basename" -}}
{{ include "fullname" . }}-{{ default "cli-relay" .Values.global.serviceDiscovery.cliRelay.name }}
{{- end }}

{{- define "safezone.cliRelay.url" -}}
http://{{ include "safezone.cliRelay.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.cliRelay.port" . }}
{{- end }}



{{/* Core */}}

{{/* Pandemic Simulator */}}

{{- define "safezone.pandemicSimulator.port" -}}
{{ default 8000 .Values.global.serviceDiscovery.simulator.port }}
{{- end }}

{{- define "safezone.pandemicSimulator.basename" -}}
{{ include "fullname" . }}-{{ default "pandemic-simulator" .Values.global.serviceDiscovery.simulator.name }}
{{- end }}


{{- define "safezone.pandemicSimulator.url" -}}
http://{{ include "safezone.pandemicSimulator.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.pandemicSimulator.port" . }}
{{- end }}


{{/* Ingestor */}}

{{- define "safezone.ingestor.port" -}}
{{ default 8000 .Values.global.serviceDiscovery.ingestor.port }}
{{- end }}

{{- define "safezone.ingestor.basename" -}}
{{ include "fullname" . }}-{{ default "ingestor" .Values.global.serviceDiscovery.ingestor.name }}
{{- end }}

{{- define "safezone.ingestor.url" -}}
http://{{ include "safezone.ingestor.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.ingestor.port" . }}
{{- end }}


{{/* Worker */}}

{{- define "safezone.worker.basename" -}}
{{ include "fullname" . }}-{{ default "worker" .Values.global.serviceDiscovery.worker.name }}
{{- end }}

{{/* Analytics API */}}

{{- define "safezone.analyticsAPI.port" -}}
{{ default 8000 .Values.global.serviceDiscovery.analyticsAPI.port }}
{{- end }}

{{- define "safezone.analyticsAPI.basename" -}}
{{ include "fullname" . }}-{{ default "analytics-api" .Values.global.serviceDiscovery.analyticsAPI.name }}
{{- end }}

{{- define "safezone.analyticsAPI.url" -}}
http://{{ include "safezone.analyticsAPI.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.analyticsAPI.port" . }}
{{- end }}



{{/* UI */}}

{{/* Dashboard */}}

{{- define "safezone.dashboard.port" -}}
{{ default 8080 .Values.global.serviceDiscovery.dashboard.port }}
{{- end }}

{{- define "safezone.dashboard.basename" -}}
{{ include "fullname" . }}-{{ default "dashboard" .Values.global.serviceDiscovery.dashboard.name }}
{{- end }}

{{- define "safezone.dashboard.url" -}}
http://{{ include "safezone.dashboard.basename" . }}.{{include "safezone.svc.postfix" . }}:{{ include "safezone.dashboard.port" . }}
{{- end }}