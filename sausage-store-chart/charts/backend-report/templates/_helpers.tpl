{{- define "backend-report.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: "{{ .Release.Name }}"
app.kubernetes.io/version: "{{ .Chart.AppVersion }}"
app.kubernetes.io/managed-by: "{{ .Release.Service }}"
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
app.kubernetes.io/component: {{ .Chart.Name }}
app.kubernetes.io/part-of: {{ .Release.Name }}
{{- end }} 

{{- define "backend-report.env" -}} 
- name: PORT
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-{{ .Chart.Name }}-conf
      key: PORT
- name: DB
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-mongodb-secret
      key: REPORT_DB_CONNECTION_STRING
{{- end }} 

{{- define "backend-report.wait-for-mongo" -}}
- name: wait-for-mongo
  image: mongo:7.0
  command:
    - sh
    - -c
    - |
      until mongosh --host {{ .Release.Name }}-mongodb-service \
          --port {{ .Values.global.mongoPort }} \
          --username "{{ .Values.global.reportDbUser }}" \
          --password "{{ .Values.global.reportDbPassword }}" \
          --authenticationDatabase "{{ .Values.global.reportDbName }}" \
          --eval "db.runCommand({ping: 1})"; do
        echo "Waiting for MongoDB..."
        sleep 3
      done
  resources:
    {{- toYaml .Values.global.initContainers.mongo.resources | nindent 4 }}
{{- end }}