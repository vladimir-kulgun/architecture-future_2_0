# Стратегический роадмап Data Mesh — «Будущее 2.0»

## Что такое Data Mesh в контексте «Будущее 2.0»

Data Mesh — это социотехнический подход к управлению данными, основанный на четырёх принципах:

| Принцип | Применение в «Будущее 2.0» |
|---------|--------------------------|
| **Domain Ownership** | Каждый домен (Clinic, Fintech, AI/ML, Corporate) владеет своими data products от сбора до витрины |
| **Data as a Product** | Gold layer каждого домена — это продукт с SLA, документацией и владельцем, а не побочный эффект работы системы |
| **Self-Service Platform** | Платформенная команда предоставляет Kafka, ClickHouse, dbt-шаблоны, DataHub — домены не строят инфраструктуру с нуля |
| **Federated Governance** | Общие стандарты (схемы событий, naming convention, классификация данных) устанавливаются централизованно; реализация — в каждом домене |

---

## Роли

### Платформенные роли (горизонтальные)

#### Platform Engineer
**Отвечает за:** инфраструктуру Data Mesh — Kafka, ClickHouse, DataHub, Superset, CI/CD пайплайны для доменов.

| Обязанности | Результат |
|------------|-----------|
| Поддерживать и развивать managed-инфраструктуру (Kafka, ClickHouse, K8s, YOS) | SLA платформы ≥ 99.9% |
| Предоставлять шаблоны: starter dbt-проект, ClickHouse DDL templates, Kafka topic provisioning | Домен создаёт первый data product за ≤ 1 неделю |
| Управлять Schema Registry, Debezium коннекторами, DataHub ingestion | Все data products зарегистрированы в DataHub |
| Настраивать OPA-политики на уровне платформы | Нарушений ACL = 0 в production |

#### Data Governance Lead
**Отвечает за:** политики, стандарты, compliance, federated governance council.

| Обязанности | Результат |
|------------|-----------|
| Устанавливать naming convention (`<domain>.<entity>.<event-type>`), стандарты схем, классификацию данных | Единый каталог стандартов в DataHub |
| Вести Data Governance Council (ежемесячно) с DPO всех доменов | Протоколы решений; метрики исполнения |
| Контролировать соответствие 152-ФЗ, 323-ФЗ, ЦБ РФ | Аудиторские отчёты без критических нарушений |
| Управлять классификационными тегами (PII, MEDICAL_RESTRICTED, FINANCIAL) | 100% датасетов классифицировано |

### Доменные роли (по одной на каждый домен)

#### Data Product Owner (DPO)
**Отвечает за:** бизнес-ценность data product своего домена.

| Обязанности | Результат |
|------------|-----------|
| Определять бизнес-метрики и KPI data product (например: clinic_visits_daily, freshness < 15 мин) | SLA определён и измеряется |
| Приоритизировать задачи Data Engineer домена | Бэклог выровнен с бизнес-целями |
| Участвовать в Data Governance Council | Интересы домена представлены |
| Принимать запросы на доступ к data product через DataHub | SLA ответа на запрос: ≤ 2 рабочих дня |

**Профиль:** Product Manager или Senior Analyst с пониманием данных домена. Не обязательно технический специалист.

#### Data Engineer
**Отвечает за:** техническую реализацию data product своего домена.

| Обязанности | Результат |
|------------|-----------|
| Разрабатывать и поддерживать Flink-джобы Bronze→Silver, dbt-модели Silver→Gold | Data product обновляется в SLA |
| Писать dbt-тесты (not_null, unique, referential_integrity, custom) | Data quality score ≥ 95% |
| Регистрировать data product в DataHub (lineage, tags, owner) | DataHub: lineage от Kafka до Gold актуален |
| Реагировать на алерты качества данных | MTTR инцидента качества ≤ 4 часа |

**Профиль:** Инженер с навыками SQL (dbt), Python (Flink/PySpark), ClickHouse. Принимает консультации от Platform Engineer.

#### BI-аналитик
**Отвечает за:** построение аналитических продуктов на основе Gold data products.

| Обязанности | Результат |
|------------|-----------|
| Строить дашборды в Apache Superset на Gold ClickHouse | Аналитики не зависят от IT для базовой отчётности |
| Документировать датасеты в DataHub (бизнес-описания, примеры использования) | Поиск в DataHub: 90% запросов — без обращения к инженерам |
| Участвовать в UX-тестировании Self-Service Portal | Feedback для улучшения платформы |
| Обучать бизнес-пользователей работе с Superset | ≥ 5 самостоятельных пользователей на домен к Году 2 |

---

## Этапы внедрения

### Этап 0: Фундамент (Месяцы 0–3)
*Цель: Подготовить платформу и команду до запуска первого домена*

```
М0         М1         М2         М3
├──────────┼──────────┼──────────┤
│ Набор    │ Kafka +  │ DataHub  │
│ Platform │ ClickHou │ + Schema │
│ team     │ se ready │ Registry │
│          │          │ + CI/CD  │
│ Стандарты│ Naming   │ Шаблоны  │
│ governance│ convention│ dbt+Flink│
```

**Задачи:**
- Сформировать Platform team (2 Platform Engineers + 1 Data Governance Lead)
- Развернуть Managed Kafka, ClickHouse, YOS, DataHub в Yandex Cloud (Terraform)
- Установить naming convention событий, DDL-шаблоны, dbt starter project
- Запустить CI/CD для доменных data products (GitHub Actions)
- Провести kick-off с будущими Domain Data Product Owners

**Бизнес-цель:** Создать надёжный фундамент; не допустить повторения ошибки "каждый домен строит свой стек".

---

### Этап 1: Пилот — Clinic Domain (Месяцы 3–9)
*Цель: Доказать концепцию на реальном домене. Создать образцовый data product.*

```
М3         М4–М5      М6–М7      М8–М9
├──────────┼──────────┼──────────┤
│ Clinic   │ Bronze → │ Gold:    │
│ DPO +    │ Silver   │ clinic_  │
│ Data Eng │ (Flink)  │ visits_  │
│ назначены│          │ daily    │
│          │ dbt:     │ DataHub: │
│ Паринг с │ Silver→  │ lineage  │
│ Platform │ Gold     │ + tags   │
│ team     │          │          │
│          │ ACL: Kafka│ Superset │
│          │ + OPA    │ dashboard│
```

**Задачи:**
- Назначить Data Product Owner и Data Engineer в Clinic домене
- Платформенный инженер работает в паре с Domain Data Engineer (паринг)
- Реализовать первый data product: `clinic_visits_daily` (Kafka → Bronze → Silver → Gold)
- Написать dbt-тесты (not_null, unique, freshness)
- Зарегистрировать data product в DataHub (lineage Kafka → Bronze → Silver → Gold)
- Подключить Clinic Gold к Superset; создать первый дашборд (загрузка клиники)
- Провести acess-тест: проверить, что медданные не проходят через Gold

**Метрики успеха пилота:**
- Freshness data product: обновление < 15 минут от события до Gold
- Data quality score: ≥ 95% (dbt tests passing)
- Data product зарегистрирован в DataHub с lineage и owner
- ≥ 1 бизнес-аналитик строит отчёты самостоятельно в Superset

**Бизнес-цель:** Показать, что команда клиники может самостоятельно управлять данными. Убедить стейкхолдеров в окупаемости инвестиций.

**Связь с бизнес-приоритетами:**
- Быстрый доступ к данным о загрузке клиник → оптимизация расписания → рост выручки
- Near-real-time инвентаризация → снижение дефицита расходников → операционная эффективность

---

### Этап 2: Масштабирование (Месяцы 9–24)
*Цель: Подключить все бизнес-критичные домены; вывести legacy; запустить Self-Service Portal*

```
М9    М12   М15   М18   М21   М24
├─────┼─────┼─────┼─────┼─────┤
│     │     │     │     │     │
│Fint │Corp │DWH  │Self-│Futu │
│ech  │oral │read │Servi│re   │
│DP   │DP   │-only│ce   │Dom. │
│     │     │→ off│Portal│ready│
│     │     │     │live │     │
│     │AI/ML│     │     │     │
│     │isol.│     │     │     │
│     │metr.│     │     │     │
```

**Задачи по месяцам:**

| Период | Домен / компонент | Ключевые задачи |
|--------|-------------------|-----------------|
| М9–М12 | **Fintech Domain** | DPO + Data Engineer назначены; data products: `fintech_transactions_daily`, `credit_portfolio`; интеграция с Regulatory Reporting |
| М9–М12 | **Clinic Domain** | Добавить data product `clinic_inventory_summary`; onboard Power BI → ClickHouse |
| М12–М15 | **Corporate / HQ Domain** | `kpi_summary_monthly`, `hr_headcount`; подключить к Superset |
| М12–М15 | **AI/ML Domain** | Публикация агрегированных метрик (без PII) в Data Catalog; подтверждение изоляции |
| М15 | **DWH** | Перевести в read-only режим; Debezium CDC остаётся для исторических данных |
| М15–М18 | **Self-Service Portal** | Superset production-ready; RBAC через OPA; DataHub доступен всем аналитикам |
| М18 | **DWH + ESB** | Вывод из эксплуатации; Debezium CDC выключен |
| М18–М24 | **Future Domains** | Pharma Partner, MedDevice — подключаются как Kafka producers; data products в DataHub |

**Метрики успеха масштабирования:**
- 4 домена с активными data products в DataHub
- DWH и ESB выведены из эксплуатации к М18
- ≥ 10 бизнес-аналитиков используют Superset самостоятельно
- Среднее время создания нового data product: ≤ 2 недели (vs ≥ 4 недели для ETL-маршрута в ESB)

**Бизнес-цель:** Устранить legacy; предоставить единый Self-Service Portal; дать бизнесу near-real-time аналитику по всем доменам.

---

### Этап 3: Поддержка и оптимизация (Месяцы 24–36)
*Цель: Data Mesh работает в устойчивом режиме; домены самостоятельны; платформа оптимизирована*

**Задачи:**

| Направление | Задачи |
|-------------|--------|
| **Governance зрелость** | Ежемесячный Data Governance Council — стандартный ритм; SLA data products измеряется автоматически в Grafana |
| **Data Quality** | Monte Carlo / Great Expectations для автоматических data quality checks без dbt; алерты на аномалии freshness и объёма |
| **FinOps** | Tiered storage в ClickHouse (горячее/холодное); TTL для Bronze (1 год); rightsizing Kafka partitions; экономия 15–20% |
| **Расширение** | Новые будущие партнёры подключаются самостоятельно по гайдлайну; платформенная команда не участвует в каждом onboarding |
| **Self-Service зрелость** | ≥ 80% аналитических запросов обрабатывается самостоятельно через Superset/DataHub без обращения к Data Engineers |
| **CQRS / Saga PoC** | Evaluate CQRS для Fintech (см. tech-radar Assess); Saga choreography для clinic-fintech billing flow |

**Метрики успеха Года 3:**
- Все домены имеют задокументированные data products с DPO и SLA
- Data Governance Council проводится регулярно; решения исполняются
- Среднее время добавления нового домена: ≤ 1 месяц
- Нет критических compliance-нарушений

---

## Привязка к бизнес-целям «Будущее 2.0»

| Бизнес-цель | Этап | Data Mesh-вклад |
|-------------|------|-----------------|
| Замена PowerBuilder и DWH к году 3 | Этап 1–2 | Clinic data product → Superset; DWH вывод М18 |
| Ускорение time-to-market для новых направлений | Этап 2–3 | Новый домен = Kafka producer + data product template; не нужен ESB |
| Соответствие 152-ФЗ / 323-ФЗ / ЦБ РФ | Этап 0–1 | DataHub классификация PII/MEDICAL; Audit Log Topic; ACL |
| AI-диагностика в near-real-time | Этап 1 | VisitCompleted → AI в секунды; нет зависимости от ночного ETL |
| Масштабирование: 50+ клиник, банк, партнёры | Этап 3 | Горизонтальное: Kafka partitions + ClickHouse shards; новый домен без изменений существующих |
| Единый Self-Service Portal для аналитиков | Этап 2 | Superset + DataHub + Gold ClickHouse по всем доменам |
| Изоляция медицинских данных | Этап 0–1 | ACL Kafka `med.*` + OPA + DataHub MEDICAL_RESTRICTED |

---

## Organizational Design: команды по доменам

```
┌─────────────────────────────────────────────────────────┐
│                   Data Governance Council                │
│  (DPO каждого домена + Platform Lead + Governance Lead)  │
└──────────────────────────┬──────────────────────────────┘
                           │  federated governance
        ┌──────────────────┼──────────────────────┐
        │                  │                       │
        ▼                  ▼                       ▼
┌──────────────┐  ┌──────────────┐       ┌──────────────────┐
│ Clinic Team  │  │ Fintech Team │  ...  │  Platform Team   │
│              │  │              │       │                  │
│ DPO          │  │ DPO          │       │ Platform Eng × 2 │
│ Data Eng × 1 │  │ Data Eng × 1 │       │ Governance Lead  │
│ BI-аналитик  │  │ BI-аналитик  │       │ DevOps/SRE       │
└──────────────┘  └──────────────┘       └──────────────────┘
```

**Принцип:** Platform team предоставляет «дорогу», доменные команды едут по ней. Платформа — enabler, не bottleneck.

---

## Ключевые риски роадмапа

| Риск | Вероятность | Митигация |
|------|:-----------:|-----------|
| DPO не назначены: команды не берут ownership | Высокая | Назначение DPO — обязательное условие начала Этапа 1; OKR DPO привязаны к data product SLA |
| Задержка вывода DWH (полит. сопротивление) | Средняя | Жёсткая freeze-дата в roadmap; CTO как sponsor; видимость прогресса через еженедельный dashboard |
| Перегрузка платформенной команды (все домены хотят помощи сразу) | Высокая | Строгая очерёдность по этапам; шаблоны снижают потребность в паринге с М9+ |
| Качество данных в Gold хуже, чем в DWH | Средняя | dbt-тесты в CI; data quality score как метрика в OKR; нельзя деплоить при failing tests |
