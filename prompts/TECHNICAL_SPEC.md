# Техническое задание: Трекер задач для МИС

## 1. Описание проекта

API-модуль трекера рабочих задач для медицинской информационной системы (МИС). Через модуль врачи и администраторы ставят себе рабочие задачи: провести операцию, связаться с клиентом, сделать обход пациентов, подготовить отчет и т.д.

---

## 2. Стек технологий

- **Ruby** 3.4.x
- **Rails** — API-only
- **PostgreSQL** 16+
- **Docker** (docker-compose: Rails API + PostgreSQL)

---

## 3. Гемы

### Runtime

| Гем | Назначение |
|-----|-----------|
| pg | PostgreSQL-адаптер |
| active_model_serializers | Сериализация JSON-ответов |
| pagy | Пагинация |
| dry-validation + dry-schema | Валидация входных данных (контракты) |
| dry-monads | Result-паттерн в сервисах |
| dry-types | Строгая типизация enum-ов и значений |
| rswag-api + rswag-ui | Swagger-документация |

### Development

| Гем | Назначение |
|-----|-----------|
| rubocop-rails-omakase | Линтинг |
| annotate | Автогенерация схемы в комментариях моделей |
| dotenv-rails | ENV-переменные |

### Test

| Гем | Назначение |
|-----|-----------|
| rspec-rails | Тестовый фреймворк |
| factory_bot_rails | Фабрики |
| shoulda-matchers | Однострочные тесты валидаций и ассоциаций |
| faker | Генерация данных |
| database_cleaner-active_record | Чистка БД между тестами |
| simplecov | Покрытие кода |
| rswag-specs | Swagger-тесты -> документация |

---

## 4. Схема базы данных

### calendar_dates (календарная таблица)

Предзаполненная dimension-таблица с датами и вычисленными атрибутами. Генерируется один раз через миграцию на 10 лет вперёд (~3650 строк). Позволяет вычислять вхождения повторяющихся задач через SQL JOIN, без логики в Ruby.

| Поле | Тип | Описание |
|------|-----|----------|
| date | date, PK | Дата |
| day_of_month | integer, NOT NULL | День месяца (1-31) |
| day_of_week | integer, NOT NULL | День недели (0-6, воскресенье-суббота) |
| is_even_day | boolean, NOT NULL | Чётное число месяца |
| month | integer, NOT NULL | Месяц (1-12) |
| year | integer, NOT NULL | Год |

**Индексы:** date (PK), day_of_month, is_even_day

**Заполнение (миграция):**

```ruby
(Date.new(2025, 1, 1)..Date.new(2035, 12, 31)).each do |date|
  CalendarDate.create!(
    date: date,
    day_of_month: date.day,
    day_of_week: date.wday,
    is_even_day: date.day.even?,
    month: date.month,
    year: date.year
  )
end
```

### tasks

| Поле | Тип | Описание |
|------|-----|----------|
| id | bigint, PK | |
| title | string, NOT NULL | Название задачи |
| description | text | Описание |
| due_date | date, NULL | Дата выполнения (для разовых задач) |
| status | enum | pending / in_progress / completed / cancelled (для разовых) |
| recurring | boolean, default: false | Флаг повторяемости |
| starts_on | date, NULL | Начало повторения |
| ends_on | date, NULL | Конец повторения (NULL = бессрочно) |
| created_at | datetime | |
| updated_at | datetime | |

### recurrence_rules (1:1 с task, только для recurring=true)

| Поле | Тип | Описание |
|------|-----|----------|
| id | bigint, PK | |
| task_id | FK, unique | Связь с задачей |
| rule_type | enum | daily / monthly / specific_dates / even_odd |
| interval | integer, default: 1 | Для daily: каждый N-й день |
| day_of_month | integer, 1-31 | Для monthly |
| specific_dates | date[] | Массив конкретных дат |
| even_odd | enum | even / odd |

### task_occurrences (материализованные экземпляры)

Создаются в БД только когда пользователь взаимодействует с конкретным экземпляром повторяющейся задачи.

| Поле | Тип | Описание |
|------|-----|----------|
| id | bigint, PK | |
| task_id | FK | Связь с задачей |
| occurrence_date | date, NOT NULL | Дата экземпляра |
| status | enum | pending / in_progress / completed / cancelled |
| title | string, NULL | Переопределение названия |
| description | text, NULL | Переопределение описания |
| cancelled | boolean, default: false | Отмена одного дня |
| created_at | datetime | |
| updated_at | datetime | |

**UNIQUE INDEX** на (task_id, occurrence_date)

### tags

| Поле | Тип | Описание |
|------|-----|----------|
| id | bigint, PK | |
| name | string, NOT NULL, unique | Название тега |
| system | boolean, default: false | Защита от удаления/изменения |

System-теги (seeds): "отчетность", "операции", "звонок"

### task_tags (M:M)

| Поле | Тип | Описание |
|------|-----|----------|
| task_id | FK | |
| tag_id | FK | |

**UNIQUE INDEX** на (task_id, tag_id)

---

## 5. Архитектура: виртуальные вхождения через календарную таблицу

### Принцип

Для повторяющихся задач используется паттерн "шаблон + виртуальные вхождения + материализация по требованию":

1. **Task** хранит шаблон: название, описание, правило повторения
2. **Вхождения вычисляются через SQL JOIN** таблицы `calendar_dates` с `recurrence_rules` для запрошенного диапазона дат
3. **TaskOccurrence** создаётся в БД **только когда** пользователь взаимодействует с конкретным экземпляром (отметил выполненным, изменил, отменил)

Это решает проблему бесконечности — никаких миллионов записей в БД.

### Календарные SQL-запросы по типам правил

**Ежедневные (каждый N-й день):**

```sql
SELECT cd.date AS occurrence_date, t.*
FROM tasks t
JOIN recurrence_rules rr ON rr.task_id = t.id
JOIN calendar_dates cd ON cd.date BETWEEN :date_from AND :date_to
WHERE rr.rule_type = 'daily'
  AND cd.date >= t.starts_on
  AND (t.ends_on IS NULL OR cd.date <= t.ends_on)
  AND (cd.date - t.starts_on) % rr.interval = 0;
```

**Чётные/нечётные дни:**

```sql
SELECT cd.date AS occurrence_date, t.*
FROM tasks t
JOIN recurrence_rules rr ON rr.task_id = t.id
JOIN calendar_dates cd ON cd.date BETWEEN :date_from AND :date_to
WHERE rr.rule_type = 'even_odd'
  AND cd.is_even_day = (rr.even_odd = 'even')
  AND cd.date >= t.starts_on
  AND (t.ends_on IS NULL OR cd.date <= t.ends_on);
```

**Ежемесячные (конкретное число):**

```sql
SELECT cd.date AS occurrence_date, t.*
FROM tasks t
JOIN recurrence_rules rr ON rr.task_id = t.id
JOIN calendar_dates cd ON cd.date BETWEEN :date_from AND :date_to
WHERE rr.rule_type = 'monthly'
  AND cd.day_of_month = rr.day_of_month
  AND cd.date >= t.starts_on
  AND (t.ends_on IS NULL OR cd.date <= t.ends_on);
```

**Конкретные даты:**

```sql
SELECT cd.date AS occurrence_date, t.*
FROM tasks t
JOIN recurrence_rules rr ON rr.task_id = t.id
JOIN calendar_dates cd ON cd.date BETWEEN :date_from AND :date_to
WHERE rr.rule_type = 'specific_dates'
  AND cd.date = ANY(rr.specific_dates)
  AND cd.date >= t.starts_on
  AND (t.ends_on IS NULL OR cd.date <= t.ends_on);
```

### Мерж виртуальных вхождений с материализованными (единый запрос)

```sql
SELECT
  cd.date AS occurrence_date,
  t.id AS task_id,
  COALESCE(o.title, t.title) AS title,
  COALESCE(o.description, t.description) AS description,
  COALESCE(o.status, 'pending') AS status,
  COALESCE(o.cancelled, false) AS cancelled
FROM tasks t
JOIN recurrence_rules rr ON rr.task_id = t.id
JOIN calendar_dates cd ON cd.date BETWEEN :date_from AND :date_to
LEFT JOIN task_occurrences o ON o.task_id = t.id AND o.occurrence_date = cd.date
WHERE <rule_type_conditions>
  AND cd.date >= t.starts_on
  AND (t.ends_on IS NULL OR cd.date <= t.ends_on)
  AND COALESCE(o.cancelled, false) = false;
```

Фильтрация, сортировка и пагинация выполняются на стороне PostgreSQL.

### Алгоритм GET /tasks?date_from=&date_to=

1. **Разовые задачи** — `WHERE due_date BETWEEN date_from AND date_to` (простой запрос)
2. **Повторяющиеся задачи** — JOIN `calendar_dates` с `recurrence_rules` + LEFT JOIN `task_occurrences` (единый SQL-запрос, см. выше)
3. **UNION** результатов в единый формат
4. Фильтрация по статусам и тегам
5. Пагинация (pagy)
6. Сериализация

Вся тяжёлая работа — на стороне PostgreSQL. Ruby-слой (сервисы) занимается оркестрацией и построением запроса.

### Исключения из правил (бонус)

- **Отменить один день** — `DELETE /tasks/:id/occurrences/:date` -> task_occurrence с `cancelled: true`
- **Изменить один день** — `PATCH /tasks/:id/occurrences/:date` с новым title/description -> task_occurrence с переопределёнными полями
- **Отметить выполненной** — `PATCH` со `status: completed` -> task_occurrence только для этого дня

---

## 6. API-эндпоинты

Базовый путь: `/api/v1/`

### Задачи

| Метод | Путь | Описание |
|-------|------|----------|
| POST | /tasks | Создание задачи (разовой или повторяющейся) |
| GET | /tasks | Список задач с фильтрацией (date_from, date_to, status[], tag_ids[]) |
| GET | /tasks/:id | Получение шаблона задачи |
| PATCH | /tasks/:id | Редактирование шаблона (влияет на всю серию) |
| DELETE | /tasks/:id | Удаление задачи целиком |

### Экземпляры повторяющихся задач

| Метод | Путь | Описание |
|-------|------|----------|
| PATCH | /tasks/:id/occurrences/:date | Изменить/выполнить конкретный день |
| DELETE | /tasks/:id/occurrences/:date | Отменить конкретный день |

### Теги

| Метод | Путь | Описание |
|-------|------|----------|
| GET | /tags | Список тегов |
| POST | /tags | Создание тега |
| PATCH | /tags/:id | Редактирование (403 для system-тегов) |
| DELETE | /tags/:id | Удаление (403 для system-тегов) |

### Привязка тегов к задачам

| Метод | Путь | Описание |
|-------|------|----------|
| POST | /tasks/:task_id/tags | Добавить тег к задаче |
| DELETE | /tasks/:task_id/tags/:id | Убрать тег с задачи |

### Формат ошибок

Единый формат: `{ error: { code, message, details } }`

---

## 7. Структура проекта

```
app/
├── controllers/
│   ├── application_controller.rb
│   └── api/
│       └── v1/
│           ├── base_controller.rb        # ErrorHandling, формат ответа
│           ├── tasks_controller.rb
│           ├── tags_controller.rb
│           ├── task_tags_controller.rb
│           └── occurrences_controller.rb
├── contracts/                            # dry-validation
│   ├── tasks/
│   │   ├── create_contract.rb
│   │   └── update_contract.rb
│   ├── tags/
│   │   └── create_contract.rb
│   └── occurrences/
│       └── update_contract.rb
├── models/
│   ├── task.rb
│   ├── recurrence_rule.rb
│   ├── task_occurrence.rb
│   ├── tag.rb
│   ├── task_tag.rb
│   └── calendar_date.rb
├── queries/
│   ├── tasks_query.rb                    # Фильтрация разовых задач
│   └── recurring_tasks_query.rb          # JOIN calendar_dates + recurrence_rules + task_occurrences
├── serializers/
│   └── api/
│       └── v1/
│           ├── task_serializer.rb
│           ├── tag_serializer.rb
│           └── occurrence_serializer.rb
├── services/
│   ├── tasks/
│   │   ├── create_service.rb
│   │   ├── update_service.rb
│   │   ├── destroy_service.rb
│   │   ├── list_service.rb               # Оркестрация: разовые UNION повторяющиеся
│   │   └── occurrence_update_service.rb  # Создание/обновление task_occurrence
│   └── tags/
│       ├── create_service.rb
│       ├── update_service.rb
│       └── destroy_service.rb
└── types.rb                              # dry-types: enum-ы
```

---

## 8. Слои приложения

| Слой | Ответственность | Инструмент |
|------|----------------|-----------|
| Контроллер | Принять запрос -> вызвать сервис -> вернуть ответ | Rails controller |
| Контракт | Валидация и приведение входных данных | dry-validation |
| Сервис | Бизнес-логика, оркестрация (Result-паттерн) | PORO + dry-monads |
| Query | SQL-запросы: JOIN calendar_dates, UNION, фильтрация | Query objects |
| Модель | Ассоциации, скоупы, AR-валидации (uniqueness и т.п.) | ActiveRecord |
| Сериализатор | Формат JSON-ответа | ActiveModel::Serializers |

Модельные валидации — только для гарантий на уровне БД. Бизнес-валидация — в контрактах.

---

## 9. Тестирование

### Стратегия

| Уровень | Что тестируем |
|---------|--------------|
| Model specs | Валидации, enum-ы, скоупы, ассоциации, защита system-тегов |
| Query specs | SQL-запросы: корректность JOIN с calendar_dates, все типы правил, граничные случаи |
| Service specs | Бизнес-логика: CRUD, оркестрация, контракты |
| Request specs | HTTP-цикл: статус-коды, JSON, фильтрация, пагинация, ошибки |
| Swagger specs | rswag генерирует спеку из тестов |

### Ключевые кейсы для RecurringTasksQuery

- daily с interval=1, interval=3
- monthly: day_of_month=31 в феврале (задача пропускается)
- even/odd дни
- specific_dates: пустой массив, даты за пределами диапазона
- граница starts_on / ends_on
- бессрочная задача (ends_on IS NULL) — проверяем что без date_from/date_to API отвечает ошибкой
- мерж с материализованными occurrences: cancelled=true исключает день, переопределённый title возвращается вместо шаблонного
- пересечение фильтров: status + tag_ids + date range

---

## 10. Допущения

- Авторизация и аутентификация не входят в скоуп — модуль без привязки к пользователям
- date_from и date_to обязательны при запросе списка задач (защита от бесконечности)
- Для monthly с day_of_month=31 в месяцах с меньшим количеством дней — задача пропускается
- Календарная таблица заполняется на 10 лет вперёд (2025-2035), расширяется при необходимости
- Пагинация через pagy после UNION-запроса
- Sidekiq/Redis не используются — вся логика вычисляется при запросе через SQL
