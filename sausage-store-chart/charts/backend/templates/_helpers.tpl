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
- name: SPRING_CLOUD_VAULT_ENABLED
  value: "{{ .Values.global.vault.enabled }}"
- name: SPRING_CLOUD_VAULT_HOST
  value: "{{ .Values.global.vault.host }}"
- name: SPRING_CLOUD_VAULT_PORT
  value: "{{ .Values.global.vault.port }}"
- name: SPRING_CLOUD_VAULT_SCHEME
  value: "{{ .Values.global.vault.scheme }}"
- name: SPRING_DATA_MONGODB_HOST
  value: {{ .Release.Name }}-mongodb-service
- name: SPRING_DATA_MONGODB_PORT
  value: "{{ .Values.global.mongoPort }}"
- name: SPRING_DATA_MONGODB_DATABASE
  value: "{{ .Values.global.reportDbName }}"
- name: SPRING_DATASOURCE_URL
  value: "jdbc:postgresql://{{ .Release.Name }}-postgresql-service:{{ .Values.global.postgresPort }}/{{ .Values.global.postgresDbName }}"
- name: REPORT_PATH
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-{{ .Chart.Name }}-conf
      key: report_path
- name: SPRING_CLOUD_VAULT_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-vault-secret
      key: vault_token
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