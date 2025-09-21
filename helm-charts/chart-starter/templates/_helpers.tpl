{{- define "your-service.name" -}}
your-service
{{- end }}

{{- define "your-service.fullname" -}}
{{ .Release.Name }}-your-service
{{- end }}
