{{- define "kafka.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "kafka.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "kafka.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "kafka.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "kafka.headlessServiceName" -}}
{{- printf "%s-headless" (include "kafka.fullname" .) -}}
{{- end -}}

{{- define "kafka.quorumVoters" -}}
{{- $fullname := include "kafka.fullname" . -}}
{{- $headless := include "kafka.headlessServiceName" . -}}
{{- $port := .Values.service.controllerPort -}}
{{- $replicas := int .Values.replicaCount -}}
{{- $voters := list -}}
{{- range $i := until $replicas -}}
{{- $id := add $i 1 -}}
{{- $entry := printf "%d@%s-%d.%s:%v" $id $fullname $i $headless $port -}}
{{- $voters = append $voters $entry -}}
{{- end -}}
{{- join "," $voters -}}
{{- end -}}
