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
  securityContext:
    runAsUser: 999
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
  command:
    - sh
    - -c
    - |
      i=0
      until mongosh --host {{ .Release.Name }}-mongodb-service \
          --port {{ .Values.global.mongoPort }} \
          --username "{{ .Values.global.reportDbUser }}" \
          --password "{{ .Values.global.reportDbPassword }}" \
          --authenticationDatabase "{{ .Values.global.reportDbName }}" \
          --eval "db.runCommand({ping: 1})"; do
        i=$((i+1))
        if [ "$i" -ge 60 ]; then
          echo "MongoDB not ready after 60 attempts"
          exit 1
        fi
        echo "Waiting for MongoDB... ($i/60)"
        sleep 3
      done
  resources:
    {{- toYaml .Values.global.initContainers.mongo.resources | nindent 4 }}  
{{- end }}

{{- define "backend.wait-for-postgres" -}}
- name: wait-for-postgres
  image: postgres:13-alpine
  securityContext:
    runAsUser: 70
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
  command:
    - sh
    - -c
    - |
      i=0
      until pg_isready -h {{ .Release.Name }}-postgresql-service -p {{ .Values.global.postgresPort }}; do
        i=$((i+1))
        if [ "$i" -ge 60 ]; then
          echo "PostgreSQL not ready after 60 attempts"
          exit 1
        fi
        echo "Waiting for PostgreSQL... ($i/60)"
        sleep 3
      done
  resources:
    requests:
      memory: "16Mi"
      cpu: "10m"
    limits:
      memory: "32Mi"
      cpu: "50m"
{{- end }}