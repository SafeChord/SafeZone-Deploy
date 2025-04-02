{{- define "producer.ingestor.fullname" -}}
{{ include "producer.fullname" . }}-covid-ingestor
{{- end }}