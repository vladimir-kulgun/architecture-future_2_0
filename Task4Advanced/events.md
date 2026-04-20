# Каталог доменных событий — «Будущее 2.0»

## Соглашения

- **Топик:** `<domain>.<entity>.<event-type>` (конвенция Kafka)
- **Формат:** Apache Avro (Schema Registry, BACKWARD_TRANSITIVE)
- **Гарантии:** at-least-once; идемпотентность на стороне консьюмера через `event_id`
- **Обязательные поля** в каждом событии: `event_id`, `event_type`, `occurred_at`, `schema_version`

---

## Clinic Domain

### Patient Flow BC

#### PatientRegistered

| Поле | Значение |
|------|---------|
| **Топик** | `clinic.patient.registered` |
| **Источник (Producer)** | Clinic API → Patient Flow BC |
| **Подписчики (Consumers)** | Fintech / Credit BC *(предложение продукта)*, Corporate / Finance BC *(статистика)*, Data Platform Bronze |
| **Семантика** | Новый пациент успешно зарегистрирован в системе |
| **Контракт (минимум)** | `event_id: UUID`, `patient_id: UUID`, `registration_date: ISO-8601`, `clinic_id: UUID`, `schema_version: "1.0"` |
| **Исключения** | PII (ФИО, дата рождения) **не включается** в событие; консьюмеры запрашивают через Clinic API при необходимости |

#### AppointmentScheduled

| Поле | Значение |
|------|---------|
| **Топик** | `clinic.appointment.scheduled` |
| **Источник** | Clinic API → Patient Flow BC |
| **Подписчики** | Clinic Operations BC *(подготовка ресурсов)*, Data Platform Bronze |
| **Семантика** | Пациенту назначен приём к конкретному врачу в конкретный слот |
| **Контракт** | `event_id`, `appointment_id: UUID`, `patient_id: UUID`, `doctor_id: UUID`, `clinic_id: UUID`, `scheduled_at: ISO-8601`, `visit_type: enum` |

#### AppointmentCancelled

| Поле | Значение |
|------|---------|
| **Топик** | `clinic.appointment.cancelled` |
| **Источник** | Clinic API → Patient Flow BC |
| **Подписчики** | Data Platform Bronze, Notification Service |
| **Семантика** | Запланированный приём отменён |
| **Контракт** | `event_id`, `appointment_id: UUID`, `cancelled_at: ISO-8601`, `cancelled_by: enum(patient|doctor|system)`, `reason_code: String` |

#### VisitCompleted

| Поле | Значение |
|------|---------|
| **Топик** | `clinic.visit.completed` |
| **Источник** | Clinic API → Clinical Operations BC |
| **Подписчики** | **AI/ML Domain** *(инициирует диагностику при наличии назначения)*, Inventory BC *(списание расходников)*, Fintech BC *(выставление счёта)*, Data Platform Bronze |
| **Семантика** | Приём завершён, процедуры зафиксированы. Ключевое событие домена — триггер для нескольких downstream процессов |
| **Контракт** | `event_id`, `visit_id: UUID`, `appointment_id: UUID`, `patient_id: UUID`, `doctor_id: UUID`, `clinic_id: UUID`, `completed_at: ISO-8601`, `procedure_codes: [String]`, `ai_study_requested: Boolean` |

#### ItemConsumed

| Поле | Значение |
|------|---------|
| **Топик** | `clinic.inventory.consumed` |
| **Источник** | Clinic API → Inventory BC |
| **Подписчики** | Inventory BC *(пополнение)*, Corporate / Finance BC *(учёт затрат)*, Data Platform Bronze |
| **Семантика** | Расходный материал использован в ходе процедуры |
| **Контракт** | `event_id`, `sku: String`, `quantity: Int`, `visit_id: UUID`, `clinic_id: UUID`, `consumed_at: ISO-8601` |

#### StockReplenished

| Поле | Значение |
|------|---------|
| **Топик** | `clinic.inventory.replenished` |
| **Источник** | Clinic API → Inventory BC |
| **Подписчики** | Data Platform Bronze |
| **Семантика** | Запас товара пополнен после получения поставки |
| **Контракт** | `event_id`, `sku: String`, `quantity_added: Int`, `new_stock_level: Int`, `supplier_id: UUID`, `replenished_at: ISO-8601` |

---

## Fintech Domain

### Accounts & Banking BC

#### AccountOpened

| Поле | Значение |
|------|---------|
| **Топик** | `fintech.account.opened` |
| **Источник** | Fintech Services → Accounts & Banking BC |
| **Подписчики** | Regulatory Reporting BC, Data Platform Bronze |
| **Семантика** | Новый банковский счёт открыт для клиента |
| **Контракт** | `event_id`, `account_id: UUID`, `account_number: String`, `client_id: UUID`, `account_type: enum`, `currency: ISO-4217`, `opened_at: ISO-8601` |

#### PaymentProcessed

| Поле | Значение |
|------|---------|
| **Топик** | `fintech.payment.processed` |
| **Источник** | Fintech Services → Accounts & Banking BC |
| **Подписчики** | Regulatory Reporting BC *(клиринг ЦБ РФ)*, Corporate / Finance BC *(выручка)*, Data Platform Bronze |
| **Семантика** | Платёж обработан, средства списаны со счёта отправителя |
| **Контракт** | `event_id`, `transaction_id: UUID`, `from_account_id: UUID`, `to_account_id: UUID`, `amount: Decimal`, `currency: ISO-4217`, `processed_at: ISO-8601`, `payment_type: enum` |

#### TransactionCompleted

| Поле | Значение |
|------|---------|
| **Топик** | `fintech.account.tx_completed` |
| **Источник** | Fintech Services → Accounts & Banking BC |
| **Подписчики** | Data Platform Bronze, Notification Service |
| **Семантика** | Транзакция окончательно подтверждена (клиринг пройден) |
| **Контракт** | `event_id`, `transaction_id: UUID`, `account_id: UUID`, `balance_after: Decimal`, `completed_at: ISO-8601` |

### Credit BC

#### CreditAgreementCreated

| Поле | Значение |
|------|---------|
| **Топик** | `fintech.credit.contract_created` |
| **Источник** | Fintech Services → Credit BC |
| **Подписчики** | Regulatory Reporting BC *(отчётность ЦБ РФ)*, Accounts & Banking BC *(резервирование лимита)*, Data Platform Bronze |
| **Семантика** | Кредитный договор подписан и вступил в силу |
| **Контракт** | `event_id`, `contract_id: UUID`, `client_id: UUID`, `account_id: UUID`, `loan_amount: Decimal`, `currency: ISO-4217`, `interest_rate: Decimal`, `term_months: Int`, `created_at: ISO-8601` |

#### LoanApproved

| Поле | Значение |
|------|---------|
| **Топик** | `fintech.credit.approved` |
| **Источник** | Fintech Services → Credit BC |
| **Подписчики** | Accounts & Banking BC *(зачислить сумму)*, Data Platform Bronze |
| **Семантика** | Заявка на кредит одобрена скоринговой системой |
| **Контракт** | `event_id`, `application_id: UUID`, `client_id: UUID`, `approved_amount: Decimal`, `approved_at: ISO-8601`, `credit_score: Int` |

#### LoanRepaid

| Поле | Значение |
|------|---------|
| **Топик** | `fintech.credit.repaid` |
| **Источник** | Fintech Services → Credit BC |
| **Подписчики** | Accounts & Banking BC, Regulatory Reporting BC, Data Platform Bronze |
| **Семантика** | Кредит погашен полностью |
| **Контракт** | `event_id`, `contract_id: UUID`, `client_id: UUID`, `total_paid: Decimal`, `repaid_at: ISO-8601` |

---

## AI/ML Domain  [ISOLATED]

### Diagnostics BC

#### AIStudyCompleted

| Поле | Значение |
|------|---------|
| **Топик** | `med.ai.diagnostic.completed` |
| **Источник** | AI Services → Diagnostics BC |
| **Подписчики** | Clinic API *(уведомить врача)*, Data Platform Bronze *(только агрегированные метрики, без PII)* |
| **Семантика** | AI-модель завершила анализ медицинского исследования |
| **Контракт** | `event_id`, `session_id: UUID`, `patient_id_pseudonymized: UUID`, `model_id: UUID`, `model_version: String`, `study_type: enum`, `result_code: enum`, `confidence: Decimal`, `completed_at: ISO-8601` |
| **Ограничения** | Топик `med.ai.*` — ACL: read только для Clinic API и AI Services; **никаких медицинских деталей** в payload; `patient_id` pseudonymized |

#### AnomalyDetected

| Поле | Значение |
|------|---------|
| **Топик** | `med.ai.anomaly.detected` |
| **Источник** | AI Services → Diagnostics BC |
| **Подписчики** | Clinic API *(приоритетный alert врачу)* |
| **Семантика** | AI обнаружил критическую аномалию, требующую немедленного внимания врача |
| **Контракт** | `event_id`, `session_id: UUID`, `patient_id_pseudonymized: UUID`, `anomaly_type: enum`, `severity: enum(low|medium|high|critical)`, `detected_at: ISO-8601` |

---

## Corporate / HQ Domain

### HR BC

#### EmployeeHired

| Поле | Значение |
|------|---------|
| **Топик** | `corp.employee.hired` |
| **Источник** | Corporate Services → HR BC |
| **Подписчики** | Identity & Access BC *(создать учётную запись)*, Data Platform Bronze |
| **Семантика** | Новый сотрудник принят на работу |
| **Контракт** | `event_id`, `employee_id: UUID`, `department_id: UUID`, `role: String`, `hired_at: ISO-8601`, `clinic_id: UUID (nullable)` |

#### EmployeeTerminated

| Поле | Значение |
|------|---------|
| **Топик** | `corp.employee.terminated` |
| **Источник** | Corporate Services → HR BC |
| **Подписчики** | **Identity & Access BC** *(немедленно отозвать все токены и доступы)*, Data Platform Bronze |
| **Семантика** | Сотрудник уволен. Критическое событие безопасности — консьюмер IAM обязан реагировать в режиме near-real-time |
| **Контракт** | `event_id`, `employee_id: UUID`, `terminated_at: ISO-8601`, `termination_type: enum(voluntary|involuntary)` |
| **SLA консьюмера** | IAM BC отзывает доступы в течение 60 секунд после получения события |

### Finance & KPI BC

#### KPIReportGenerated

| Поле | Значение |
|------|---------|
| **Топик** | `corp.kpi.report_generated` |
| **Источник** | Corporate Services → Finance & KPI BC |
| **Подписчики** | Data Platform Bronze *(Gold → дашборды)*, Regulatory Reporting BC |
| **Семантика** | Ежемесячный/ежеквартальный KPI-отчёт сформирован и готов к просмотру |
| **Контракт** | `event_id`, `snapshot_id: UUID`, `period: YYYY-MM`, `report_url: String`, `generated_at: ISO-8601` |

---

## Future Domains

#### DrugSupplyUpdated

| Поле | Значение |
|------|---------|
| **Топик** | `pharma.drug.supply_updated` |
| **Источник** | Pharma Services (внешний Kafka Producer) |
| **Подписчики** | Clinic / Inventory BC *(актуализировать каталог препаратов)*, Data Platform Bronze |
| **Семантика** | Фармацевтический партнёр обновил данные о доступности препарата |
| **Контракт** | `event_id`, `drug_id: String`, `drug_name: String`, `available_quantity: Int`, `price: Decimal`, `updated_at: ISO-8601` |

#### DeviceTelemetryReceived

| Поле | Значение |
|------|---------|
| **Топик** | `meddev.device.telemetry` |
| **Источник** | MedDevice Services (IoT Connector via Kafka Connect) |
| **Подписчики** | AI/ML Domain *(мониторинг показателей)*, Data Platform Bronze |
| **Семантика** | Медицинское устройство передало телеметрический пакет данных |
| **Контракт** | `event_id`, `device_id: UUID`, `device_type: enum`, `clinic_id: UUID`, `measurements: [{metric: String, value: Decimal, unit: String}]`, `recorded_at: ISO-8601` |

---

## Сводная таблица событий

| Событие | Топик | Источник | Ключевые подписчики |
|---------|-------|----------|---------------------|
| PatientRegistered | `clinic.patient.registered` | Clinic / Patient Flow | Fintech, Data Platform |
| AppointmentScheduled | `clinic.appointment.scheduled` | Clinic / Patient Flow | Clinic Ops, Data Platform |
| AppointmentCancelled | `clinic.appointment.cancelled` | Clinic / Patient Flow | Data Platform |
| **VisitCompleted** | `clinic.visit.completed` | Clinic / Clinical Ops | **AI/ML, Fintech, Inventory, Data Platform** |
| ItemConsumed | `clinic.inventory.consumed` | Clinic / Inventory | Corporate, Data Platform |
| StockReplenished | `clinic.inventory.replenished` | Clinic / Inventory | Data Platform |
| AccountOpened | `fintech.account.opened` | Fintech / Banking | Regulatory, Data Platform |
| PaymentProcessed | `fintech.payment.processed` | Fintech / Banking | Regulatory, Corporate, Data Platform |
| TransactionCompleted | `fintech.account.tx_completed` | Fintech / Banking | Data Platform |
| CreditAgreementCreated | `fintech.credit.contract_created` | Fintech / Credit | Regulatory, Banking, Data Platform |
| LoanApproved | `fintech.credit.approved` | Fintech / Credit | Banking, Data Platform |
| LoanRepaid | `fintech.credit.repaid` | Fintech / Credit | Regulatory, Data Platform |
| **AIStudyCompleted** | `med.ai.diagnostic.completed` | AI/ML / Diagnostics | Clinic API *(alert)* |
| AnomalyDetected | `med.ai.anomaly.detected` | AI/ML / Diagnostics | Clinic API *(alert)* |
| EmployeeHired | `corp.employee.hired` | Corporate / HR | IAM, Data Platform |
| **EmployeeTerminated** | `corp.employee.terminated` | Corporate / HR | **IAM (SLA 60s)**, Data Platform |
| KPIReportGenerated | `corp.kpi.report_generated` | Corporate / Finance | Data Platform |
| DrugSupplyUpdated | `pharma.drug.supply_updated` | Pharma (external) | Clinic Inventory |
| DeviceTelemetryReceived | `meddev.device.telemetry` | MedDevice (IoT) | AI/ML, Data Platform |

**Жирным** выделены события с наибольшим числом подписчиков или критичными SLA.
