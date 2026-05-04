# План управления рисками — «Будущее 2.0»

## Принципы

1. **Снижение** — устранить причину риска техническими или организационными мерами.
2. **Передача** — перенести риск на managed-сервисы или страхование (vendor SLA).
3. **Принятие** — осознанно принять риск с мониторингом и планом реагирования.
4. **Избегание** — изменить архитектуру или процесс, чтобы риск не возник.

---

## Технические меры снижения рисков

### A1 — Потеря данных при CDC-миграции

**Стратегия:** Снижение

| Мера | Детали |
|------|--------|
| Debezium offset tracking | Коннектор хранит offset в Kafka: при перезапуске продолжает с того же места, не пропуская события |
| Reconciliation job | Ежедневная сверка: `COUNT(*)` и checksum по ключевым таблицам DWH vs агрегаты в Bronze/Gold |
| Dual-write с shadow mode | Этап 1: оба пути активны, новый путь (Kafka) — shadow (не production). Переключение только после подтверждения консистентности |
| Transaction log retention | Увеличить retention лога SQL Server на период миграции; настроить alert при приближении к лимиту |
| Rollback plan | Если расхождение > 0.01%, автоматический rollback флага трафика на DWH-путь |

### A2 — Несовместимость схем событий

**Стратегия:** Снижение + Избегание

| Мера | Детали |
|------|--------|
| Schema Registry (Apicurio) | Единый реестр схем с версионированием Avro / Protobuf |
| BACKWARD_TRANSITIVE compatibility | Новая схема обязана читаться всеми существующими консьюмерами — проверяется при регистрации |
| CI-проверка схемы | В CI/CD: `mvn avro:check` / `buf lint` — PR не мёрджится при нарушении совместимости |
| Deprecation период | Breaking change невозможен без предварительного 2-недельного deprecation period в каналах команд |
| Consumer group monitoring | Alert при падении consumer group после деплоя продюсера — быстрое обнаружение несовместимости |

### A3 — Деградация производительности при dual-write

**Стратегия:** Снижение

| Мера | Детали |
|------|--------|
| Feature flags | Постепенный перевод трафика: 5% → 20% → 50% → 100% на новый Kafka-путь с rollback за 30 секунд |
| Async write в DWH | В shadow-период запись в DWH асинхронная (best-effort), не блокирует основной поток |
| Latency мониторинг | Grafana dashboard: p99 latency DWH-path vs Kafka-path; SLO: p99 < 500ms |
| Load testing | Нагрузочное тестирование dual-write сценария до начала этапа 1 миграции |

### A4 — Нарушение изоляции медицинских данных

**Стратегия:** Снижение (Defence in depth)

| Слой | Мера |
|------|------|
| Kafka ACL | Топики `med.*` — write-only для AI Services; read запрещён для всех остальных доменов |
| ClickHouse row policies | `CREATE ROW POLICY` на уровне таблиц: `department_id = 'ai'` фильтрует строки |
| DataHub тег | `MEDICAL_RESTRICTED` на всех AI-domain датасетах; автоматический блок в Self-Service Portal |
| Сетевая изоляция | AI/ML домен в отдельном VPC / subnet без прямого маршрута в portal subnet |
| CI access tests | Автоматические тесты в pipeline: попытка SELECT через аналитика → ожидаем 0 строк или ошибку доступа |

### A5 — Vendor lock-in

**Стратегия:** Снижение + Принятие

| Мера | Детали |
|------|--------|
| Open standards | S3 API (не YOS-specific), Apache Kafka protocol, ClickHouse SQL совместим с ANSI SQL |
| Kafka Connect абстракция | Коннекторы работают с любым Kafka-совместимым брокером (MSK, Confluent, self-hosted) |
| dbt vendor-neutral | dbt profiles настраиваются на любой SQL-совместимый хранилище; при смене DWH меняется только profile |
| Infrastructure as Code | Terraform с модулями: замена провайдера требует переписать только ресурсы, не архитектуру |
| Периодическая оценка | Ежегодный review альтернатив и стоимости миграции |

### T1 — SQL Server 2008 EOL

**Стратегия:** Снижение (срочно)

| Мера | Детали |
|------|--------|
| Приоритет в Этапе 1 | Вывод DWH из эксплуатации — цель Этапа 1 (год 1), не откладывать |
| Extended Security Updates | Подключить ESU от Microsoft на период миграции (платные патчи безопасности) |
| Сетевая изоляция | DWH в изолированном network segment; доступ только через ESB/Debezium; никакого прямого доступа из интернета |
| WAF + IDS | Web Application Firewall и Intrusion Detection на периметре сегмента с DWH |
| Мониторинг CVE | Подписка на NVD feed для SQL Server 2008; immediate response plan при критических CVE |

### T2 — Операционная сложность Kafka

**Стратегия:** Передача + Снижение

| Мера | Детали |
|------|--------|
| Managed Kafka (Yandex) | Vendor управляет broker patching, replication, ZK/KRaft — снимает основную ops-нагрузку |
| Centralized monitoring | Prometheus + Grafana: consumer lag, DLQ size, under-replicated partitions, disk usage |
| Alerts | PagerDuty: DLQ lag > 100 messages, consumer lag > 10k, broker down |
| Runbook для DLQ | Задокументированный playbook: как идентифицировать failed event, исправить и reprocess |
| Chaos engineering | Ежеквартальное учение: намеренное отключение одного broker — проверка failover |

### T4 — Отсутствие state locking в YOS

**Стратегия:** Снижение

| Мера | Детали |
|------|--------|
| GitHub Actions concurrency | `concurrency: group: terraform-<env>`, `cancel-in-progress: false` — только один apply на окружение одновременно |
| `use_lockfile = true` | Terraform >= 1.10: файловый lock в S3 bucket предотвращает конкурентный apply |
| Separate state per env | Изолированные state файлы: `envs/dev/`, `envs/stage/`, `envs/prod/` — нет конкуренции между окружениями |

---

## Управленческие меры снижения рисков

### O1 — Нехватка data engineering экспертизы

**Стратегия:** Снижение

| Мера | Детали |
|------|--------|
| Platform team enablement | Платформенная команда создаёт шаблоны: стартовый dbt-проект, ClickHouse DDL templates, DataHub ingestion configs |
| Паринг | При создании первого data product в домене — платформенный инженер работает в паре с доменной командой 2–4 недели |
| Внутренние гильдии | Еженедельные Data Engineering Guild встречи: sharing опыта между доменными командами |
| Обучение | Спонсируемые курсы: dbt Fundamentals (free), ClickHouse Academy, Kafka certification |
| Метрики готовности | Перед передачей домена в production: checklist компетенций (тест схемы, мониторинг, rollback procedure) |

### O2 — Сопротивление смене UI

**Стратегия:** Снижение

| Мера | Детали |
|------|--------|
| Пилотный запуск | Новый Clinic Web App запускается в 1–2 клиниках-добровольцах до широкого rollout |
| Вовлечение врачей | UX-исследование: врачи участвуют в тестировании прототипов с этапа дизайна |
| Параллельная работа | PowerBuilder UI и Web UI работают одновременно в период перехода; врач может вернуться на старый UI |
| Champion program | Назначить "clinic champion" в каждой клинике — врач-энтузиаст, обучающий коллег и собирающий feedback |
| Training sessions | Обязательные тренинги по новому UI с отработкой ключевых сценариев |

### O3 — Отсутствие культуры domain ownership

**Стратегия:** Снижение

| Мера | Детали |
|------|--------|
| Data Product Owner | В каждом домене назначается Data Product Owner (DPO) — роль с явными обязанностями и метриками |
| SLA на data products | Каждый data product имеет SLA: freshness (обновление не реже X), quality score (% failed dbt tests < Y) |
| Data quality dashboard | DataHub / Monte Carlo: автоматические alerts DPO при деградации качества данных |
| OKR интеграция | Метрики data quality включены в OKR доменных команд и отчётность перед CTO |
| Governance council | Ежемесячный Data Governance Council: DPO всех доменов + платформенная команда + CISO |

### O4 — Замедление time-to-market

**Стратегия:** Снижение

| Мера | Детали |
|------|--------|
| Legacy freeze date | Публичное объявление: с даты X (конец Этапа 1) новая бизнес-логика реализуется только на новой платформе |
| Strangler Fig pattern | Новые features в доменах идут через Kafka + новые API; DWH остаётся read-only |
| Метрики миграции | Еженедельный дашборд: % функциональности перенесено, оставшийся legacy backlog |
| Dedicated migration team | Выделенная команда (3–5 инженеров) занимается только migration, не конкурируя с feature-командами |

### T3 — Несоответствие регуляторным требованиям

**Стратегия:** Снижение + Передача

| Регулятор | Требование | Мера |
|-----------|-----------|------|
| 152-ФЗ | Локализация персональных данных в РФ | Yandex Cloud data centers в РФ; ФСТЭК-сертификация YC |
| 152-ФЗ | Согласие на обработку, право на забвение | Data Catalog классифицирует PII; automated delete workflow |
| 323-ФЗ | Конфиденциальность медицинских данных | Medical Storage изолирован; audit log всех обращений |
| ЦБ РФ | Хранение финансовых данных, audit trail | Immutable Audit Log Topic (retention 5 лет); ClickHouse append-only tables |
| Общее | Привлечь compliance с Этапа 1 | DPO (Data Protection Officer) участвует в design review каждого нового data flow |

### T5 — Рост стоимости инфраструктуры

**Стратегия:** Снижение

| Мера | Детали |
|------|--------|
| TTL для Bronze данных | Bronze Zone: retention 1 год, затем автоматическое удаление или перенос в холодное хранилище |
| Tiered storage ClickHouse | Горячие данные (последние 90 дней) на SSD; холодные на HDD / YOS |
| Kafka partition rightsizing | Начать с минимального числа партиций; масштабировать по измеренному throughput |
| FinOps team | Ежемесячный cloud cost review: выявление idle ресурсов, rightsizing, reserved instances |
| Cost alerts | Alert при превышении месячного бюджета на 10% — анализ причин |

---

## Сводная таблица рисков и мер

| ID | Приоритет | Стратегия | Тип меры | Срок |
|----|-----------|-----------|----------|------|
| O1 | Критический | Снижение | Управленческая | Этап 1 |
| O3 | Критический | Снижение | Управленческая | Этап 1 |
| T1 | Критический | Снижение | Техническая | Немедленно |
| A1 | Высокий | Снижение | Техническая | Этап 1 |
| A2 | Высокий | Снижение | Техническая | Этап 1 |
| A3 | Высокий | Снижение | Техническая | Этап 1–2 |
| O4 | Высокий | Снижение | Управленческая | Этап 1 |
| T2 | Высокий | Передача + Снижение | Техническая | Этап 1 |
| T3 | Высокий | Снижение + Передача | Управленческая | Этап 1 |
| A4 | Средний | Снижение (defence in depth) | Техническая | Этап 1 |
| A5 | Средний | Снижение + Принятие | Техническая | Этапы 1–3 |
| O2 | Средний | Снижение | Управленческая | Этап 2 |
| T5 | Средний | Снижение | Техническая | Этап 2 |
| T4 | Низкий | Снижение | Техническая | Этап 1 |
