# Task2Advanced — Terraform + S3 Backend + GitHub Actions CI/CD

Расширение Task1Advanced: удалённое хранение Terraform state в Yandex Object Storage и автоматизированный деплой через GitHub Actions с approval gate для stage и prod.

## Архитектура

```
.github/workflows/
├── terraform-dev.yml    # push → main  → auto apply
├── terraform-stage.yml  # push → release/** → apply с подтверждением
└── terraform-prod.yml   # workflow_dispatch  → apply с подтверждением

Task2Advanced/
├── modules/vm/          # переиспользуемый модуль ВМ (из Task1Advanced)
└── envs/
    ├── dev/   → state: s3://tfstate-future20/envs/dev/terraform.tfstate
    ├── stage/ → state: s3://tfstate-future20/envs/stage/terraform.tfstate
    └── prod/  → state: s3://tfstate-future20/envs/prod/terraform.tfstate
```

Каждое окружение — изолированный state файл. `terraform destroy` в dev не затрагивает stage или prod.

## Безопасность: что хранится где

| Данные | Место хранения |
|--------|---------------|
| YC IAM-токен | GitHub Secret: `YC_TOKEN` |
| Backend static key ID | GitHub Secret: `TF_BACKEND_ACCESS_KEY` |
| Backend static secret | GitHub Secret: `TF_BACKEND_SECRET_KEY` |
| `subnet_id` per env | GitHub Secrets: `TF_VAR_SUBNET_ID_DEV/STAGE/PROD` |
| `ssh_public_key` | GitHub Secret: `TF_VAR_SSH_PUBLIC_KEY` |
| `YC_CLOUD_ID`, `YC_FOLDER_ID` | GitHub Secrets |
| Несекретные параметры (cores, memory…) | `*.tfvars` в репозитории |

Ни один секрет не хранится в `.tfvars`, `backend.hcl` или коде.

## Предварительная настройка

### 1. Создать S3 bucket в Yandex Object Storage

```bash
yc storage bucket create --name tfstate-future20
```

### 2. Создать сервисный аккаунт и статические ключи для backend

```bash
# Создать сервисный аккаунт
yc iam service-account create --name tf-backend-sa

# Выдать права на bucket
yc storage bucket update tfstate-future20 \
  --grants grant-type=grant-type-account,grantee-id=<SA_ID>,permission=permission-full-control

# Создать статический ключ
yc iam access-key create --service-account-name tf-backend-sa
# → сохранить key_id и secret
```

### 3. Настроить GitHub Secrets

В `Settings → Secrets and variables → Actions` добавить:

| Secret | Значение |
|--------|----------|
| `YC_TOKEN` | IAM-токен: `yc iam create-token` |
| `YC_CLOUD_ID` | `yc config get cloud-id` |
| `YC_FOLDER_ID` | `yc config get folder-id` |
| `TF_BACKEND_ACCESS_KEY` | `key_id` из шага 2 |
| `TF_BACKEND_SECRET_KEY` | `secret` из шага 2 |
| `TF_VAR_SUBNET_ID_DEV` | ID подсети для dev |
| `TF_VAR_SUBNET_ID_STAGE` | ID подсети для stage |
| `TF_VAR_SUBNET_ID_PROD` | ID подсети для prod |
| `TF_VAR_SSH_PUBLIC_KEY` | Содержимое публичного SSH-ключа |

### 4. Настроить GitHub Environments с approval gate

В `Settings → Environments`:

| Environment | Required reviewers | Назначение |
|-------------|-------------------|-----------|
| `dev` | нет | авто-деплой после успешного plan |
| `stage` | 1+ reviewer | деплой требует ручного подтверждения |
| `production` | 1+ reviewer | деплой требует ручного подтверждения |

После добавления reviewer в Environment — job `apply` будет ждать его одобрения перед выполнением.

## Локальный запуск

```bash
# Экспортировать credentials
export AWS_ACCESS_KEY_ID=<static_key_id>
export AWS_SECRET_ACCESS_KEY=<static_key_secret>
export YC_TOKEN=<iam_token>
export YC_CLOUD_ID=<cloud_id>
export YC_FOLDER_ID=<folder_id>

# Секретные Terraform-переменные
export TF_VAR_subnet_id=<subnet_id>
export TF_VAR_ssh_public_key="ssh-rsa AAAA..."

# Dev
cd Task2Advanced/envs/dev
terraform init -backend-config=backend.hcl
terraform plan  -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Stage
cd ../stage
terraform init -backend-config=backend.hcl
terraform plan  -var-file="stage.tfvars"
terraform apply -var-file="stage.tfvars"

# Prod
cd ../prod
terraform init -backend-config=backend.hcl
terraform plan  -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## CI/CD пайплайн

### Триггеры

| Окружение | Триггер | Apply |
|-----------|---------|-------|
| dev | push → `main` (path: `envs/dev/**` или `modules/**`) | автоматически |
| stage | push → `release/**` или `workflow_dispatch` | после подтверждения reviewer |
| prod | только `workflow_dispatch` | после подтверждения reviewer |

### Логика выполнения

```
[push / dispatch]
       │
       ▼
   ┌────────┐
   │  plan  │  init → validate → plan -out=tfplan → upload artifact (1 day)
   └───┬────┘
       │
       ▼
   ┌──────────────────────────────────┐
   │  APPROVAL GATE (stage / prod)   │  ← reviewer нажимает "Approve" в GitHub UI
   └───┬──────────────────────────────┘
       │
       ▼
   ┌────────┐
   │  apply │  download artifact → init → apply tfplan
   └────────┘
```

`terraform apply tfplan` применяет именно тот план, который прошёл review — не новый.

### Защита от конкурентных запусков

```yaml
concurrency:
  group: terraform-<env>
  cancel-in-progress: false
```

Если запущены два workflow на одно окружение одновременно — второй ждёт завершения первого. Это предотвращает конфликты записи в state файл.

## Проверка state в bucket

```bash
# Список state файлов
yc storage object list --bucket tfstate-future20

# Убедиться, что state не хранится локально
ls -la Task2Advanced/envs/dev/  # не должно быть terraform.tfstate
```

## Требования

- Terraform >= 1.3
- Провайдер `yandex-cloud/yandex` ~> 0.90
- Yandex CLI (`yc`) для первоначальной настройки
- GitHub репозиторий с настроенными Secrets и Environments
