# Task3Advanced — C4-архитектура и карта рисков «Будущее 2.0»

Целевая архитектура системы на горизонте 3 лет в C4-нотации, карта рисков трансформации и план управления рисками.

## Структура

```
Task3Advanced/
├── diagrams/
│   ├── c4-context.puml                    # C4 L1: System Context
│   ├── c4-containers.puml                 # C4 L2: Containers (TO-BE, год 3)
│   ├── c4-components-event-platform.puml  # C4 L3: Event Streaming Platform + Processing Layer
│   └── c4-components-data-platform.puml   # C4 L3: Data Platform + Self-Service Portal
├── esb-decomposition.md                  # Декомпозиция функций ESB → целевая архитектура
├── risk-map.md                            # Карта рисков с тепловой картой (14 рисков)
├── risk-management-plan.md               # Технические и управленческие меры снижения
└── README.md
```

## C4-диаграммы

### Уровень 1 — System Context (`c4-context.puml`)

Границы системы «Будущее 2.0» и внешние акторы:
- Пациент, Врач, Бизнес-аналитик, Регулятор
- Внешние системы: Фармацевтический партнёр, Производитель мед. оборудования, ЦБ РФ / НСПК, ЕГИСЗ

### Уровень 2 — Containers (`c4-containers.puml`)

Шесть доменных областей + платформенные сервисы:

| Домен | Ключевые контейнеры |
|-------|---------------------|
| Clinic | React Web App, Go API, PostgreSQL, ClickHouse Gold |
| Fintech | Go/Java Services, Banking Core, PostgreSQL, ClickHouse Gold |
| AI/ML `[ISOLATED]` | Python Services, Medical Storage (encrypted), MLflow |
| Corporate / HQ | Go/Java Services, ClickHouse Gold |
| Future Domains | Pharma Services, MedDevice Services (Kafka producers) |
| Platform | Kafka, API Gateway (Kong), DataHub, Superset, YOS |
| Legacy `[MIGRATION BRIDGE]` | DWH SQL Server 2008, ESB Apache Camel, PowerBuilder UI |

**Ключевое ограничение:** AI/ML домен изолирован — медицинские данные не попадают в Self-Service Portal.

### Уровень 3 — Event Streaming Platform (`c4-components-event-platform.puml`)

Диаграмма показывает три слоя, которые вместе заменяют функции Apache Camel ESB:

**Integration Adapter Layer** (заменяет Camel-компоненты для внешних протоколов):

| Компонент | Технология | Функция ESB |
|-----------|-----------|------------|
| CDC Adapter | Kafka Connect + Debezium | JDBC Source Connector → SQL Server |
| HL7 / FHIR Adapter | Go микросервис (ACL) | Camel HL7 Component → ЕГИСЗ |
| Banking Adapter | Go микросервис (ACL) | Camel SWIFT / HTTP → ЦБ РФ |
| IoT / MQTT Adapter | Kafka Connect MQTT | Camel MQTT Component → MedDevice |

**Event Streaming Platform** (только транспорт, Kafka ≠ ESB):

| Компонент | Технология | Функция ESB |
|-----------|-----------|------------|
| Kafka Broker | Apache Kafka, RF=3 | Message Channel (только доставка) |
| Schema Registry | Apicurio (Avro) | ФЛК уровень 2: структурная валидация |
| Kafka Connect + SMT | Single Message Transforms | Простой field mapping без кода |
| Topic ACL | Kafka ACL + naming convention | Content-Based Router → топология топиков |
| DLQ Topics | `dlq.<domain>.*` | Dead Letter Channel |
| Audit Log Topic | `audit.events`, retention 5 лет | Audit interceptor (compliance) |

**Stream Processing Layer** (заменяет Camel EIP-трансформации):

| Компонент | Технология | Функция ESB |
|-----------|-----------|------------|
| Stream Validator | Apache Flink | ФЛК уровень 3: бизнес-правила на потоке |
| Stream Transformer | Apache Flink | Stateful enrichment, дедупликация, windows |
| Stream Router/Splitter | Apache Flink Side Outputs | Splitter + Recipient List EIP |
| Batch Transformer | dbt Core | Batch aggregation → Gold витрины |

### Уровень 3 — Data Platform (`c4-components-data-platform.puml`)

Medallion architecture (Bronze → Silver → Gold) per domain + Self-Service Portal:

| Зона | Хранилище | Особенности |
|------|-----------|-------------|
| Bronze | Yandex Object Storage, Parquet/Avro | Immutable, retention 1 год |
| Silver | Yandex Object Storage, Parquet | Дедупликация, типы, null-проверки, retention 3 года |
| Gold | ClickHouse, MergeTree | Бизнес-агрегаты, near-real-time через Flink |
| ACL Layer | OPA + ClickHouse row policies | RBAC по доменам, аудит доступа |
| DataHub Connector | DataHub Ingestion | Lineage: Kafka → Bronze → Silver → Gold |

## Рендеринг диаграмм

### Онлайн
Открыть [plantuml.com/plantuml](https://www.plantuml.com/plantuml/uml/) и вставить содержимое `.puml` файла.

### Локально (Docker)
```bash
docker run --rm -v "$(pwd)/diagrams:/data" plantuml/plantuml -tpng /data/*.puml
```

### VS Code
Расширение **PlantUML** (jebbs.plantuml) + локальный PlantUML jar или сервер.

```bash
# Установить PlantUML jar
brew install plantuml   # macOS
# или скачать plantuml.jar с plantuml.com

# Рендер всех диаграмм в PNG
java -jar plantuml.jar diagrams/*.puml
```

## Карта рисков

Файл `risk-map.md` содержит 14 рисков в трёх категориях:

| Категория | Кол-во | Приоритет |
|-----------|--------|-----------|
| Архитектурные (A1–A5) | 5 | A1, A2, A3 — Высокий |
| Организационные (O1–O4) | 4 | O1, O3 — Критический |
| Технологические (T1–T5) | 5 | T1 — Критический |

Тепловая карта и детальное описание каждого риска — в `risk-map.md`.

## План управления рисками

Файл `risk-management-plan.md` содержит конкретные меры для каждого риска:
- **Технические:** Schema Registry, Debezium offset tracking, Feature flags, Defence in depth для медданных, Managed Kafka
- **Управленческие:** Data Product Owner, domain enablement, compliance integration, Legacy freeze date

## Связь с Task1Advanced и Task2Advanced

| Компонент | Task1 | Task2 | Task3 |
|-----------|-------|-------|-------|
| Terraform-модуль ВМ | ✓ | — | — |
| Remote state (YOS) | — | ✓ | — |
| CI/CD с approval gate | — | ✓ | — |
| C4 архитектура | — | — | ✓ |
| Object Storage в архитектуре | — | tfstate | Bronze/Silver/tfstate |
| Риск T4 (state locking) | — | решён через concurrency | задокументирован |
