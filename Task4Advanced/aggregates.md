# Агрегаты «Будущее 2.0» — описание, границы и инварианты

## Clinic Domain

### Patient Flow BC

#### Агрегат: Patient

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `Patient` |
| **Идентичность** | `patient_id: UUID` (генерируется при регистрации) |
| **Границы** | Включает: Demographics, ContactInfo. **Не включает:** медицинские записи, снимки, истории болезни (принадлежат AI/ML домену) |
| **Инварианты** | `full_name` не пустое; `birth_date` ≤ today; один активный `primary_contact`; PII хранится только в Clinic DB, не реплицируется в Data Platform |
| **Команды** | `RegisterPatient`, `UpdateContactInfo`, `DeactivatePatient` |
| **События** | `PatientRegistered`, `PatientContactUpdated`, `PatientDeactivated` |

#### Агрегат: Appointment

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `Appointment` |
| **Идентичность** | `appointment_id: UUID` |
| **Границы** | Включает: временной слот, ссылку на `patient_id`, ссылку на `doctor_id`, статус |
| **Инварианты** | Слот не пересекается с другим `Appointment` того же врача; `scheduled_at` > now при создании; статус: `scheduled → confirmed → in_progress → completed | cancelled` |
| **Команды** | `ScheduleAppointment`, `ConfirmAppointment`, `CancelAppointment`, `StartVisit` |
| **События** | `AppointmentScheduled`, `AppointmentConfirmed`, `AppointmentCancelled`, `VisitStarted` |

### Clinical Operations BC

#### Агрегат: Visit

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `Visit` |
| **Идентичность** | `visit_id: UUID` |
| **Границы** | Включает: список `Procedure`, список `PrescribedItem` (ссылки на SKU из Inventory), ссылку на `appointment_id`, `doctor_id`. **Не включает:** медицинские заключения (AI домен) |
| **Инварианты** | `Visit` создаётся только из `Appointment` в статусе `confirmed`; список процедур не пустой при завершении; `completed_at` > `started_at` |
| **Команды** | `StartVisit`, `AddProcedure`, `CompleteVisit` |
| **События** | `VisitStarted`, `ProcedureCompleted`, `VisitCompleted` |

### Inventory BC

#### Агрегат: InventoryItem

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `InventoryItem` |
| **Идентичность** | `sku: String` (артикул товара) |
| **Границы** | Включает: `StockLevel`, `ReorderPoint`, `Supplier` |
| **Инварианты** | `stock_level` ≥ 0 (нельзя уйти в минус — транзакция отклоняется); при `stock_level` < `reorder_point` — автоматически создаётся `RestockRequest` |
| **Команды** | `ConsumeItem`, `ReplenishStock`, `UpdateReorderPoint` |
| **События** | `ItemConsumed`, `StockReplenished`, `RestockThresholdReached` |

---

## Fintech Domain

### Accounts & Banking BC

#### Агрегат: Account

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `Account` |
| **Идентичность** | `account_id: UUID` + `account_number: String` (банковский номер счёта) |
| **Границы** | Включает: `Balance`, список `Transaction` (последние N за период для согласованности), `AccountStatus` |
| **Инварианты** | `balance` ≥ 0 для дебетовых счетов; `status`: `active | frozen | closed`; нельзя провести транзакцию по `frozen` или `closed` счёту |
| **Команды** | `OpenAccount`, `FreezeAccount`, `CloseAccount`, `Deposit`, `Withdraw` |
| **События** | `AccountOpened`, `AccountFrozen`, `AccountClosed`, `TransactionCompleted` |

#### Агрегат: Transaction

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `Transaction` |
| **Идентичность** | `transaction_id: UUID` (идемпотентный ключ: `client_request_id`) |
| **Границы** | Включает: `amount`, `currency`, `from_account_id`, `to_account_id`, `status`, `processed_at` |
| **Инварианты** | Идемпотентность: повторный вызов с тем же `client_request_id` возвращает существующую транзакцию; финальные статусы (`completed`, `failed`) не изменяются |
| **Команды** | `InitiatePayment`, `ConfirmPayment`, `ReverseTransaction` |
| **События** | `PaymentProcessed`, `TransactionCompleted`, `TransactionFailed`, `TransactionReversed` |

### Credit BC

#### Агрегат: CreditAgreement

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `CreditAgreement` |
| **Идентичность** | `contract_id: UUID` |
| **Границы** | Включает: `Loan` (сумма, ставка, срок), `RepaymentSchedule`, `CreditScore` (snapshot на момент выдачи), ссылку на `account_id` |
| **Инварианты** | `loan_amount` > 0; `interest_rate` ∈ [0, 100]; сумма задолженности не может превысить `credit_limit` клиента; статус: `pending → approved | rejected → active → closed` |
| **Команды** | `ApplyCreditApplication`, `ApproveLoan`, `RejectLoan`, `RecordRepayment`, `CloseLoan` |
| **События** | `CreditApplicationSubmitted`, `LoanApproved`, `LoanRejected`, `CreditAgreementCreated`, `RepaymentRecorded`, `LoanRepaid` |

---

## AI/ML Domain  [ISOLATED]

### Diagnostics BC

#### Агрегат: DiagnosticSession

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `DiagnosticSession` |
| **Идентичность** | `session_id: UUID` |
| **Границы** | Включает: ссылку на `patient_id` (pseudonymized), список `MedicalImage` (S3 keys), `ModelVersion`, `DiagnosticResult` |
| **Инварианты** | `patient_id` pseudonymized перед сохранением; `result` immutable после публикации `AIStudyCompleted`; данные не покидают AI/ML domain |
| **Команды** | `InitiateDiagnosticSession`, `UploadMedicalImage`, `RunInference`, `PublishResult` |
| **События** | `DiagnosticSessionStarted`, `MedicalImageUploaded` *(внутр.)*, `AIStudyCompleted`, `AnomalyDetected` |

### Model Management BC

#### Агрегат: MLModel

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `MLModel` |
| **Идентичность** | `model_id: UUID` + `version: SemVer` |
| **Границы** | Включает: `Experiment` (MLflow run_id, metrics), `Artifact` (S3 path), `DeploymentStatus` |
| **Инварианты** | Деплой только при accuracy ≥ threshold; `version` монотонно возрастает; предыдущая версия не удаляется до валидации новой |
| **Команды** | `TrainModel`, `ValidateModel`, `DeployModel`, `RollbackModel` |
| **События** | `ModelTrained`, `ModelValidated`, `ModelDeployed`, `ModelRetrained` *(внутр.)* |

---

## Corporate / HQ Domain

### HR BC

#### Агрегат: Employee

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `Employee` |
| **Идентичность** | `employee_id: UUID` |
| **Границы** | Включает: `PersonalInfo`, `EmploymentContract`, `RoleAssignment`, `AccessProfile` |
| **Инварианты** | Не может быть двух активных контрактов у одного сотрудника; при увольнении `AccessProfile` деактивируется автоматически через Policy |
| **Команды** | `HireEmployee`, `AssignRole`, `TerminateEmployee`, `TransferEmployee` |
| **События** | `EmployeeHired`, `RoleChanged`, `EmployeeTransferred`, `EmployeeTerminated` |

### Finance & KPI BC

#### Агрегат: KPISnapshot

| Атрибут | Значение |
|---------|---------|
| **Корень агрегата** | `KPISnapshot` |
| **Идентичность** | `snapshot_id: UUID` + `period: YYYY-MM` |
| **Границы** | Агрегирует данные из Gold Data Products всех доменов через витрину ClickHouse |
| **Инварианты** | Один `KPISnapshot` на период; immutable после публикации; не содержит медицинских данных |
| **Команды** | `GenerateKPIReport`, `ApproveReport`, `SubmitRegulatoryReport` |
| **События** | `KPIReportGenerated`, `RegulatoryReportSubmitted` |

---

## Сводная таблица агрегатов

| Агрегат | Домен / BC | Identity Key | Публикует события |
|---------|-----------|-------------|-------------------|
| Patient | Clinic / Patient Flow | `patient_id` | `clinic.patient.*` |
| Appointment | Clinic / Patient Flow | `appointment_id` | `clinic.appointment.*` |
| Visit | Clinic / Clinical Ops | `visit_id` | `clinic.visit.*` |
| InventoryItem | Clinic / Inventory | `sku` | `clinic.inventory.*` |
| Account | Fintech / Banking | `account_id` | `fintech.account.*` |
| Transaction | Fintech / Banking | `transaction_id` | `fintech.payment.*` |
| CreditAgreement | Fintech / Credit | `contract_id` | `fintech.credit.*` |
| DiagnosticSession | AI-ML / Diagnostics | `session_id` | `med.ai.diagnostic.*` |
| MLModel | AI-ML / Model Mgmt | `model_id`+`version` | внутренние |
| Employee | Corporate / HR | `employee_id` | `corp.employee.*` |
| KPISnapshot | Corporate / Finance | `snapshot_id`+`period` | `corp.kpi.*` |
