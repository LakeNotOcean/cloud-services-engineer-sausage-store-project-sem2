{{- define "backend.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: "{{ .Release.Name }}"
app.kubernetes.io/version: "{{ .Chart.AppVersion }}"
app.kubernetes.io/managed-by: "{{ .Release.Service }}"
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
app.kubernetes.io/component: {{ .Chart.Name }}
app.kubernetes.io/part-of: {{ .Release.Name }}
{{- end }} 
{{- define "backend.env" -}}
- name: SPRING_DATA_MONGODB_URI
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-mongodb-secret
      key: REPORT_DB_CONNECTION_STRING
- name: SPRING_DATASOURCE_URL
  value: "jdbc:postgresql://{{ .Release.Name }}-postgresql-service:{{ .Values.global.postgresPort }}/{{ .Values.global.postgresDbName }}"
- name: SPRING_DATASOURCE_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-postgresql-secret
      key: POSTGRES_USER
- name: SPRING_DATASOURCE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-postgresql-secret
      key: POSTGRES_PASSWORD
- name: REPORT_PATH
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-{{ .Chart.Name }}-conf
      key: report_path
- name: LOG_PATH
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-{{ .Chart.Name }}-conf
      key: log_path
{{- end }}
{{- define "backend.wait-for-mongo" -}}
- name: wait-for-mongo
  image: mongo:7.0
  command:
    - mongosh
  args:
    - --host
    - {{ .Release.Name }}-mongodb-service
    - --port
    - "{{ .Values.global.mongoPort }}"
    - --username
    - "{{ .Values.global.reportDbUser }}"
    - --password
    - "{{ .Values.global.reportDbPassword }}"
    - --authenticationDatabase
    - "{{ .Values.global.reportDbName }}"
    - --eval
    - "db.runCommand({ping: 1})"
  resources:
    {{- toYaml .Values.global.initContainers.mongo.resources | nindent 4 }}
{{- end }}