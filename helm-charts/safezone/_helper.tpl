{{/*
Common helper functions for SafeZone umbrella chart
*/}}

{{- define "safezone.simulatorUrl" -}}
http://{{ .Release.Name }}-covid-simulator:8000
{{- end }}

{{- define "safezone.analyticsUrl" -}}
http://{{ .Release.Name }}-analytics-api:8000
{{- end }}

{{- define "safezone.dashboardUrl" -}}
http://{{ .Release.Name }}-dashboard:8080
{{- end }}

{{- define "safezone.externalPostgresUrl" -}}
{{- if and .Values.db.external.enabled .Values.db.external.username }}
postgres://{{ .Values.db.external.username }}:{{ .Values.db.external.password }}@{{ .Values.db.external.host }}:{{ .Values.db.external.port }}/{{ .Values.db.external.database }}
{{- else -}}
{{ fail "externalPostgresUrl is undefined: values-secret.yaml 未正確覆蓋 db.external.* 欄位" }}
{{- end }}
{{- end }}