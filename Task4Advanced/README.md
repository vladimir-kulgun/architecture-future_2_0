# Task4Advanced — DDD, Event Storming и событийная архитектура «Будущее 2.0»

Доменная декомпозиция системы по принципам DDD, Event Storming с каталогом событий и обоснование перехода от Apache Camel ESB к событийной платформе на Kafka.

## Структура

```
Task4Advanced/
├── bounded-contexts.puml   # Context Map: домены, BC, паттерны интеграции
├── event-storming.puml     # Big Picture Event Storming (Commands → Events → Policies)
├── aggregates.md           # Агрегаты: границы, инварианты, identity keys
├── events.md               # Каталог доменных событий (19 событий, контракты)
├── justification.md        # Обоснование событийного подхода vs ESB/DWH
└── README.md
```

## Домены и Bounded Contexts

| Домен | Bounded Contexts | Ключевые агрегаты |
|-------|-----------------|-------------------|
| Clinic | Patient Flow, Clinical Operations, Inventory | Patient, Appointment, Visit, InventoryItem |
| Fintech | Accounts & Banking, Credit, Regulatory Reporting | Account, Transaction, CreditAgreement |
| AI/ML `[ISOLATED]` | Diagnostics, Model Management | DiagnosticSession, MLModel |
| Corporate / HQ | HR, Finance & KPI | Employee, KPISnapshot |
| Platform | Event Infrastructure, Identity & Access, Data Catalog | — |
| Legacy `[ACL]` | DWH Adapter, ESB Bridge | — (transitional) |

## Ключевые события по доменам

| Домен | Событие | Топик Kafka |
|-------|---------|-------------|
| Clinic | VisitCompleted | `clinic.visit.completed` |
| Clinic | PatientRegistered | `clinic.patient.registered` |
| Fintech | CreditAgreementCreated | `fintech.credit.contract_created` |
| Fintech | PaymentProcessed | `fintech.payment.processed` |
| AI/ML | AIStudyCompleted | `med.ai.diagnostic.completed` |
| Corporate | EmployeeTerminated | `corp.employee.terminated` |

Полный каталог (19 событий) — в `events.md`.

## Рендеринг диаграмм

```bash
# Онлайн: plantuml.com — вставить содержимое .puml файла

# Локально
java -jar plantuml.jar bounded-contexts.puml event-storming.puml

# Docker
docker run --rm -v "$(pwd):/data" plantuml/plantuml -tpng /data/*.puml
```

## Связь с Task3Advanced

C4 Level 2 (Containers) из Task3Advanced описывает те же домены на уровне контейнеров. Task4Advanced детализирует **внутреннюю структуру** каждого домена: bounded contexts, агрегаты и события.

| Task3Advanced | Task4Advanced |
|---------------|---------------|
| Clinic Domain → `clinic_api`, `clinic_db`, `clinic_dp` | Clinic BC: Patient Flow, Clinical Ops, Inventory |
| Event Streaming Platform (Kafka) | Топики: `clinic.*`, `fintech.*`, `med.ai.*`, `corp.*` |
| AI/ML Domain `[ISOLATED]` | Diagnostics BC: ACL топик `med.ai.*`, pseudonymized patient_id |
