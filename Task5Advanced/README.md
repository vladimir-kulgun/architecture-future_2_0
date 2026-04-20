# Task5Advanced — Технологический стек, TCO и роадмап Data Mesh

Технологический радар, экономическое обоснование трансформации и стратегический план внедрения Data Mesh для «Будущее 2.0».

## Структура

```
Task5Advanced/
├── tech-radar.md        # Расширенный технорадар: 35+ технологий и паттернов
├── tco-analysis.md      # TCO: AS-IS vs TO-BE на 3 года, ROI, breakeven
├── datamesh-roadmap.md  # Роадмап Data Mesh: роли, 4 этапа, бизнес-цели
└── README.md
```

## Ключевые выводы

### Технорадар

| Кольцо | Технологии / паттерны |
|--------|-----------------------|
| **Adopt** | Go, Python, Kafka, ClickHouse, PostgreSQL, dbt, Terraform, EDA, DDD, Medallion, IaC, Strangler Fig |
| **Trial** | Flink, DataHub, OPA, Superset, Apicurio, MLflow, Kong, Data Mesh, Self-Service BI |
| **Assess** | OpenTelemetry, HashiCorp Vault, CQRS, Circuit Breaker, Saga |
| **Hold** | PowerBuilder, Apache Camel ESB, SQL Server 2008, Power BI *(transitional)*, Batch ETL |

### TCO (3 года)

| | AS-IS | TO-BE | Разница |
|-|------:|------:|--------:|
| Прямые затраты | 1 630 800 $ | 2 117 100 $ | +486 300 $ |
| Деловая ценность | — | ~1 200 000 $ | |
| **Чистая выгода (NPV)** | | | **+713 700 $** |

Инвестиция окупается с середины Года 2.

### Роадмап Data Mesh

| Этап | Период | Ключевой результат |
|------|--------|-------------------|
| **0. Фундамент** | М0–М3 | Платформа развёрнута, стандарты определены |
| **1. Пилот** | М3–М9 | Clinic Domain: первый data product в production |
| **2. Масштабирование** | М9–М24 | 4 домена, DWH выведен (М18), Self-Service Portal |
| **3. Поддержка** | М24–М36 | Все домены самостоятельны, FinOps, CQRS PoC |

## Связь с предыдущими заданиями

| Задание | Артефакт | Связь |
|---------|----------|-------|
| Task3 | C4 Containers | Домены → доменные команды в роадмапе |
| Task3 | Risk Map | O1 (нехватка экспертизы), O3 (нет ownership) → митигируются ролями DPO и Data Engineer |
| Task4 | Event Storming | События `clinic.*`, `fintech.*` → топики в Tech Radar (Kafka) |
| Task2 | CI/CD + Terraform | IaC → Adopt в Tech Radar; GitHub Actions → основа платформенного CI/CD |
