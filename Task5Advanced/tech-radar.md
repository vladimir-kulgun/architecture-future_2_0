# Расширенный технологический радар — «Будущее 2.0»

## Методология

Радар построен по модели Thoughtworks Technology Radar. Четыре кольца:

| Кольцо | Значение |
|--------|---------|
| **Adopt** | Доказано в production. Рекомендуется для всех новых проектов |
| **Trial** | Используется в «Будущее 2.0». Требует накопления экспертизы, но вектор верный |
| **Assess** | Перспективно. Проводятся PoC или активное изучение |
| **Hold** | Не рекомендуется к расширению. Используется только там, где уже есть. Выводится |

Четыре квадранта: **Языки и фреймворки · Платформы и инфраструктура · Данные и аналитика · Архитектурные паттерны**

---

## Квадрант 1: Языки и фреймворки

| Технология | Кольцо | Применение в «Будущее 2.0» | Обоснование |
|-----------|:------:|--------------------------|-------------|
| **Go** | Adopt | Clinic API, Fintech Services, Corporate Services | Высокая производительность, простота операционного управления, сильная стандартная библиотека для HTTP/gRPC |
| **Python** | Adopt | AI Services, ML Platform, dbt-расширения | De facto стандарт ML/AI; FastAPI даёт production-ready REST; зрелая экосистема для data science |
| **SQL (ANSI + диалекты)** | Adopt | dbt-трансформации, ClickHouse, PostgreSQL-запросы | Lingua franca аналитики; dbt позволяет версионировать и тестировать SQL как код |
| **TypeScript / React** | Adopt | Clinic Web App (замена PowerBuilder) | Типобезопасность снижает количество ошибок в UI; React — промышленный стандарт веб-разработки |
| **Java** | Trial | Fintech Services (унаследованная кодовая база Banking Core) | Используется там, где уже есть; новые сервисы предпочтительнее писать на Go |
| **HCL (Terraform)** | Adopt | Инфраструктура всех окружений (dev/stage/prod) | IaC как стандарт; строгая типизация ресурсов; зрелый провайдер Yandex Cloud |
| **YAML (GitHub Actions, K8s)** | Adopt | CI/CD пайплайны, Kubernetes манифесты | Стандарт декларативной конфигурации в облачной экосистеме |
| **PowerBuilder** | Hold | Legacy Clinic UI (выводится) | EOL-технология; активная миграция на React. Новые экраны — только на TypeScript |

---

## Квадрант 2: Платформы и инфраструктура

| Технология | Кольцо | Применение в «Будущее 2.0» | Обоснование |
|-----------|:------:|--------------------------|-------------|
| **Yandex Cloud** | Adopt | Основная облачная платформа: Managed Kafka, ClickHouse, YOS, K8s | ФСТЭК-сертификация удовлетворяет 152-ФЗ; датацентры в РФ; managed-сервисы снижают ops-нагрузку |
| **Kubernetes (Managed YC)** | Adopt | Оркестрация микросервисов доменов; Flink jobs | Стандарт оркестрации; managed K8s снимает overhead управления control plane |
| **GitHub Actions** | Adopt | CI/CD для Terraform, сервисов, dbt | Нативная интеграция с репозиторием; Environments + approval gate для stage/prod |
| **Kong API Gateway** | Trial | Единая точка входа к доменным API; auth, rate limiting | Open-source, проверенный в production; декларативная конфигурация через deck; ещё нет экспертизы в команде |
| **Prometheus + Grafana** | Adopt | Мониторинг Kafka, ClickHouse, сервисов, Terraform state | Промышленный стандарт observability; богатые дашборды; интеграция с managed YC |
| **OpenTelemetry** | Assess | Распределённая трассировка между доменными сервисами | Вендор-нейтральный стандарт; PoC планируется в Q2. Позволит трассировать путь события Kafka от продюсера до консьюмера |
| **HashiCorp Vault** | Assess | Централизованное управление секретами (БД-пароли, API-ключи) | Сейчас секреты в GitHub Secrets — достаточно для CI/CD. Vault нужен при росте числа сервисов и ротации ключей |
| **Apache Camel ESB** | Hold | Legacy интеграционная шина (выводится) | Заменяется Kafka + Kafka Connect. Новые маршруты не создавать; заморозить после Этапа 1 |
| **SQL Server 2008** | Hold | Legacy DWH (выводится) | EOL с 2019; уязвимости безопасности; заменяется ClickHouse + Object Storage. Read-only с Этапа 2, вывод — Этап 1 |

---

## Квадрант 3: Данные и аналитика

| Технология | Кольцо | Применение в «Будущее 2.0» | Обоснование |
|-----------|:------:|--------------------------|-------------|
| **Apache Kafka (Managed YC)** | Adopt | Event Streaming Platform: все доменные события | Промышленный стандарт event streaming; at-least-once, replay, topic ACL, retention; managed снимает ops |
| **ClickHouse (Managed YC)** | Adopt | Gold layer всех доменных data products | Колончатое хранилище; векторизованные агрегаты; ClickHouse MergeTree — оптимален для аналитических запросов |
| **PostgreSQL** | Adopt | Операционные базы Clinic, Fintech, Corporate доменов | ACID; богатая экосистема расширений; зрелый провайдер Terraform |
| **dbt Core** | Adopt | SQL-трансформации Silver → Gold; тесты качества данных | SQL как код; версионирование трансформаций; встроенные тесты not_null/unique/referential_integrity; CI-интеграция |
| **Apache Flink** | Trial | Stream processing Bronze→Silver→Gold; near-real-time агрегаты | Stateful stream processing; exactly-once поверх Kafka; требует накопления экспертизы; Flink SQL упрощает onboarding |
| **Apicurio Schema Registry** | Trial | Версионирование Avro/Protobuf схем; BACKWARD_TRANSITIVE | Open-source альтернатива Confluent Schema Registry; поддерживает OpenAPI, Avro, Protobuf; менее зрелый, чем Confluent |
| **DataHub** | Trial | Data Catalog: lineage, классификация, search, data products | Open-source; богатый UI; автоматическая регистрация из dbt и ClickHouse; команде нужна экспертиза настройки |
| **Apache Superset** | Trial | Self-Service BI: drag-and-drop отчёты, дашборды | Open-source; подключается к ClickHouse нативно; RBAC; требует UI/UX настройки под аналитиков |
| **Yandex Object Storage (S3)** | Adopt | Bronze/Silver слои (Parquet/Avro); Terraform state; ML artifacts | S3-совместимый API; интеграция с Kafka S3 Sink; шифрование server-side; ФСТЭК-сертификация |
| **Apache Parquet / Avro** | Adopt | Форматы хранения Bronze (Avro), Silver/Gold-экспорт (Parquet) | Parquet: колончатый, эффективен для аналитических запросов; Avro: строгая схема для streaming |
| **MLflow** | Trial | Версионирование ML-моделей, эксперименты, model registry | De facto стандарт для ML lifecycle; интеграция с Python; изолирован в AI/ML домене |
| **Power BI** | Hold | Переходный период: существующие отчёты на ClickHouse | Переключён с DWH на ClickHouse Gold; новые отчёты — только в Superset. Вывод по мере миграции аналитиков |
| **Debezium CDC** | Adopt | CDC из SQL Server → Kafka в период миграции | Единственный надёжный способ читать transaction log SQL Server без изменения источника |
| **OPA (Open Policy Agent)** | Trial | RBAC для доменных данных; ClickHouse row policies; Kafka topic ACL | Policy-as-code; интеграция с ClickHouse и Kafka ACL; команде нужна экспертиза написания Rego-политик |

---

## Квадрант 4: Архитектурные паттерны

| Паттерн | Кольцо | Применение в «Будущее 2.0» | Обоснование |
|---------|:------:|--------------------------|-------------|
| **Event-Driven Architecture (EDA)** | Adopt | Основа интеграции всех доменов через Kafka | Decoupling продюсеров и консьюмеров; горизонтальное масштабирование; async resilience; заменяет синхронный ESB |
| **Domain-Driven Design (DDD)** | Adopt | Декомпозиция системы на bounded contexts; убиквитарный язык | Выравнивает техническую модель с бизнес-моделью; чёткие границы ownership; основа для команды по домену |
| **Infrastructure as Code (IaC)** | Adopt | Terraform для всей инфраструктуры dev/stage/prod | Воспроизводимость, code review инфраструктуры, drift detection, rollback |
| **Medallion Architecture (Bronze/Silver/Gold)** | Adopt | Слои данных в Data Platform каждого домена | Разделение raw / cleaned / business данных; каждый слой имеет чёткий контракт качества |
| **Data Mesh** | Trial | Доменное владение data products; federated governance | Устраняет bottleneck центральной data-команды; домены отвечают за качество своих данных; требует зрелости команд |
| **Self-Service BI** | Trial | Apache Superset для бизнес-аналитиков без помощи IT | Снижает нагрузку на BI-команду; аналитики строят отчёты самостоятельно; требует обучения и Data Catalog |
| **Strangler Fig** | Adopt | Постепенная замена DWH/ESB: новая логика → Kafka, старая → ESB (read-only) | Снижает риск миграции; позволяет итеративно переносить функциональность без остановки системы |
| **Anti-Corruption Layer (ACL)** | Adopt | DWH Adapter BC и ESB Bridge BC в период миграции | Изолирует legacy-модель от новой доменной модели; Debezium CDC как ACL для SQL Server |
| **CQRS (Command Query Responsibility Segregation)** | Assess | Разделение write (Kafka events) и read (ClickHouse Gold) путей | Позволяет оптимизировать read и write независимо; хорошо сочетается с EDA; PoC на Fintech домене |
| **Circuit Breaker** | Assess | Resilience паттерн для синхронных вызовов между сервисами (Kong plugins) | Актуален для gRPC-вызовов через API Gateway; предотвращает каскадные отказы; изучается в контексте Kong |
| **Saga (Choreography-based)** | Assess | Распределённые транзакции между Clinic и Fintech (выставление счёта) | Необходим при eventual consistency между доменами; choreography через Kafka events; сложность — компенсирующие транзакции |
| **Batch ETL (монолитный)** | Hold | Ночная загрузка из DWH в Power BI | Заменяется stream processing (Flink) + Medallion. Batch-подход оставить только для bulk historical loads |
| **Point-to-Point Integration** | Hold | Прямые REST-вызовы между доменами минуя Gateway | Нарушает domain ownership; создаёт невидимые зависимости; все sync вызовы — только через API Gateway |

---

## Сводная визуализация радара

```
                         ADOPT
    ┌────────────────────────────────────────────────────────┐
    │  Go · Python · SQL · TypeScript/React · HCL            │
    │  Kafka · ClickHouse · PostgreSQL · YOS · dbt           │
    │  Yandex Cloud · K8s · GitHub Actions · Prometheus      │
    │  EDA · DDD · IaC · Medallion · Strangler Fig · ACL     │
    └────────────────────────────────────────────────────────┘
                         TRIAL
    ┌────────────────────────────────────────────────────────┐
    │  Java · Kong · Flink · Apicurio · DataHub              │
    │  Superset · MLflow · OPA                               │
    │  Data Mesh · Self-Service BI                           │
    └────────────────────────────────────────────────────────┘
                         ASSESS
    ┌────────────────────────────────────────────────────────┐
    │  OpenTelemetry · HashiCorp Vault                       │
    │  CQRS · Circuit Breaker · Saga (Choreography)          │
    └────────────────────────────────────────────────────────┘
                         HOLD
    ┌────────────────────────────────────────────────────────┐
    │  PowerBuilder · Apache Camel ESB · SQL Server 2008     │
    │  Power BI (transitional) · Batch ETL · P2P Integration │
    └────────────────────────────────────────────────────────┘
```
