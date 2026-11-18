# Sausage Store

Учебный проект по развертыванию инфраструктуры в Yandex Cloud с тестированием (Terraform, Checkov, Terratest), установкой Vault через Ansible и деплоем приложения в Kubernetes по методологии GitOps (ArgoCD).

## Компоненты приложения

| Компонент | Стек | Хранилище |
|-----------|------|-----------|
| frontend | Angular, nginx (nginx-unprivileged), проксирует `/api` на backend | — |
| backend | Java 17, Spring Boot 2.6, Spring Data JPA, Flyway, Spring Cloud Vault | PostgreSQL |
| backend-report | Go | MongoDB |

В кластере БД разворачиваются чартом следующим образом: PostgreSQL (Deployment, PVC), MongoDB (StatefulSet, PVC) и init-Job, создающий пользователя Mongo. Данные авторизации в БД backend получает из Vault.

## Компоненты облачной инфраструктуры

- Yandex Cloud: VPC, подсети и VM контуров dev/prod, группы безопасности.
- SG prod открытые порты:
  - 22 (ssh)
  - 8200 (Vault) 
- SG dev открытые порты:
  - 22 (ssh)
  - 8200 (Vault) 
  - 443 (Vault)
- Terraform state хранится в GitLab.
- Актуальные IP VM (могут измениться при пересоздании VM):
  - vm-dev: `84.201.133.236`
  - vm-prod: `84.201.159.151`
- Тесты в CI. Представлены Checkov (кастомная политика `ensure_yandex_instance_has_labels`, конфиг `.checkov.yml`, soft-fail) и Terratest (`vm_avalability_test.go`, `vm_prod_sg_check_test.go`).

## Компненты Vault

- Vault запускается в docker-контейнере в dev-режиме на **vm-dev**.
- Установка с помощью Ansible. Для развертывания описаны роли `docker` и `vault`, плейбук `vault-playbook.yml`. 
- Ииспользуется порт **8200**.
- Доступно по адресу `http://84.201.133.236:8200` (также `:443`).
- Ansible записывает в Vault секреты (`spring.datasource.username/password`, `spring.data.mongodb.uri` и др.) из переменных окружения.

## Компоненты CI/CD

Пайплайн запускается вручную с выбором операции `OPERATION`:

- **terraform**: `fmt`/checkov -> `plan` -> (`apply` (manual) → `terratest`) или `destroy` (manual).
- **ansible**: syntax-check -> `ansible_deploy` (manual).
- **k8s**: `docker_build_push` (сборка образов backend/frontend/backend-report (теги `latest` + SHA коммита())) -> `helm_package_push` (manual) (версия чарта `0.1.<pipeline_iid>`, упаковка и загрузка в Nexus).

Артефакты, получаемые в ходе выполнения пайплайнов: 
- образы на DockerHub (`lakenotocean/sausage-*`), 
- Helm-чарт на Nexus `https://nexus.infra.students-projects.ru/repository/s18727602-helm`.

## GitOps-деплой

- Application `sausage-store-s18727602`;
- Project `s18727602`;
  манифест `argocd/sausage-store.yml`.
- Источниклм является Helm-чарт `sausage-store` из Nexus, используется `targetRevision: 0.1.*` и auto-sync.
- Назначение: `https://kubernetes.default.svc`, namespace `ep-namespace-a4970852f9974b88b52fea26-g1`.
- Ingress `http://s18727602.2sem.students-projects.ru`.

В манифесте требется указать реальный Vault-токен и другие переменные окружения.

## Переменные CI/CD

Для корректной работы требуется установить следующие перменные:

- Terraform: `AUTHORIZED_KEY`, `TF_HTTP_PASSWORD_SECRET`, `TF_VAR_FOLDER_ID`, `TF_VAR_ZONE`, `TF_VAR_CATALOG_NAME`, `TF_VAR_IMAGE_ID`, `TF_VAR_VM_USER`, `TF_VAR_SSH_PUBLIC_KEY`, `TF_VAR_CORES`, `TF_VAR_MEMORY`, `TF_VAR_CORE_FRACTION`, `TF_VAR_DISK_SIZE`.
- Ansible/Vault: `VM_DEV_IP_ADDRESS`, `SSH_PRIVATE_KEY_B64`, `VAULT_TOKEN`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `SPRING_DATA_MONGODB_URI`, `MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD`, `REPORT_DB_USER`, `REPORT_DB_PASSWORD`.
- k8s: `DOCKER_USER`, `DOCKER_PASSWORD`, `NEXUS_HELM_REPO`, `NEXUS_HELM_REPO_USER`, `NEXUS_HELM_REPO_PASSWORD`.

## Структура репозитория

```
├── .gitlab-ci.yml / .gitlab/ci/        # пайплайны terraform / ansible / k8s
├── argocd/sausage-store.yml            # Application ArgoCD
├── infra/                              # Terraform, Checkov-политики, Terratest
├── ansible/                            # роли docker/vault, inventory, плейбук
├── sausage-store-chart/                # Helm-чарт (backend, backend-report, frontend, infra, vault)
├── backend/ frontend/ backend-report/  # код приложений
└── README.md
```

## Локальные проверки

```bash
helm lint sausage-store-chart
helm template sausage-store sausage-store-chart
```