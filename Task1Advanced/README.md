# vm_module — Переиспользуемый Terraform-модуль для ВМ (Yandex Cloud)

Модуль создаёт виртуальную машину (`yandex_compute_instance`) с подключаемым диском (`yandex_compute_disk`) в Yandex Cloud. Все параметры передаются через переменные — хардкода нет.

## Структура

```
TaskAdvanced1/
├── modules/
│   └── vm/
│       ├── main.tf        # ресурсы ВМ + диск
│       ├── variables.tf   # входные параметры
│       └── outputs.tf     # выходные значения
└── envs/
    ├── dev/               # dev: 2 CPU / 4 GB / HDD 20 GB
    ├── stage/             # stage: 4 CPU / 8 GB / HDD 50 GB
    └── prod/              # prod: 8 CPU / 16 GB / SSD 100 GB
```

## Входные параметры модуля

| Переменная | Тип | Описание | Значение по умолчанию |
|-----------|-----|----------|-----------------------|
| `env_name` | string | Имя окружения — используется в именах ресурсов | — |
| `cores` | number | Количество vCPU | — |
| `memory` | number | Объём RAM в GB | — |
| `disk_size` | number | Размер подключаемого диска в GB | — |
| `disk_type` | string | Тип диска: `network-hdd` / `network-ssd` | `network-hdd` |
| `image_id` | string | ID образа ОС в Yandex Cloud | — |
| `platform_id` | string | Платформа ВМ: `standard-v2` / `standard-v3` | `standard-v2` |
| `subnet_id` | string | ID подсети | — |
| `ssh_public_key` | string | Содержимое SSH публичного ключа | — |
| `zone` | string | Зона доступности (например, `ru-central1-a`) | `ru-central1-a` |
| `boot_disk_size` | number | Размер boot-диска в GB | `20` |
| `boot_disk_type` | string | Тип boot-диска | `network-hdd` |

## Выходные значения

| Output | Описание |
|--------|----------|
| `vm_id` | ID виртуальной машины |
| `vm_name` | Имя виртуальной машины |
| `internal_ip` | Внутренний IP-адрес |
| `external_ip` | Внешний NAT IP-адрес |
| `disk_id` | ID подключаемого диска |

## Конфигурации окружений

| Параметр | dev | stage | prod |
|---------|-----|-------|------|
| `cores` | 2 | 4 | 8 |
| `memory` | 4 GB | 8 GB | 16 GB |
| `disk_size` | 20 GB | 50 GB | 100 GB |
| `disk_type` | network-hdd | network-hdd | network-ssd |
| `platform_id` | standard-v2 | standard-v2 | standard-v3 |

## Требования

- Terraform >= 1.3
- Провайдер `yandex-cloud/yandex` ~> 0.90
- Переменные окружения для аутентификации:
  ```bash
  export YC_TOKEN="your-iam-token"
  export YC_CLOUD_ID="your-cloud-id"
  export YC_FOLDER_ID="your-folder-id"
  ```

## Запуск

Перед запуском замените в `.tfvars` нужного окружения:
- `subnet_id` — ID вашей подсети
- `ssh_public_key` — содержимое вашего публичного SSH-ключа
- `image_id` при необходимости (Ubuntu 22.04 LTS по умолчанию)

### dev

```bash
cd envs/dev
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

### stage

```bash
cd envs/stage
terraform init
terraform plan -var-file="stage.tfvars"
terraform apply -var-file="stage.tfvars"
```

### prod

```bash
cd envs/prod
terraform init
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

### Удаление ресурсов

```bash
terraform destroy -var-file="<env>.tfvars"
```
