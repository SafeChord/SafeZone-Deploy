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

{{/* a copy of umbrella helpers.tpl - SafeZone default ports / constants */}}

{{- define "safezone.cliRelay.port" -}}
8000
{{- end }}

{{- define "safezone.cliRelay.svcnames" -}}
safezone-cli-relay
{{- end }}

{{- define "safezone.cliRelay.url" -}}
http://{{ include "safezone.cliRelay.serviceName" . }}:{{ include "safezone.cliRelay.port" . }}
{{- end }}