# Задача: Трекер задач для медицинского персонала

Необходимо создать Ruby on Rails приложение — трекер рабочих задач для медицинской системы. Врачи и администраторы ставят себе задачи: провести операцию, обзвонить пациентов, подготовить отчёт и тд

На первом этапе реализуем только API-часть, но приложение должно быть полноценным Rails-приложением, чтобы в дальнейшем добавить фронтенд на Hotwire (Turbo + Stimulus). API-контроллеры живут в `api/v1/` namespace, фронтовые контроллеры будут добавлены позже в корне.

## Стек приложения

- Ruby 3.4, Rails, PostgreSQL 16+
- Docker (docker-compose: rails + postgres)
- RSpec, factory_bot, shoulda-matchers, faker, database_cleaner, simplecov - для тестов
- rswag - документация из тестов
- dry-validation, dry-monads, dry-types - типы, контракты
- active_model_serializers, pagy - сериализаторы и пагинация
- rubocop-rails-omakase, annotate, dotenv-rails

## Общая архитектура приложения

Сервисный слой: тонкие контроллеры, вся бизнес-логика в сервисах. Валидация входных данных — через dry-validation. В моделях только ассоциации, скоупы, валидации на уровне бд. Сложные SQL-запросы в query objects.

Структура:
- `app/controllers/api/v1/` — контроллеры
- `app/contracts/` — dry-validation контракты
- `app/services/` — сервисы
- `app/queries/` — query objects
- `app/serializers/api/v1/` — сериализаторы
- `app/types.rb` — dry-types

Единый формат ошибок: `{ error: { code, message, details } }`. Обработка через concern в base_controller.

Первый этап реализации

### 1. 

Задача (Task) имеет: title, description, due_date (дата выполнения), status (pending/in_progress/completed/cancelled).

Эндпоинты:
- `POST /api/v1/tasks` — создание
- `GET /api/v1/tasks` — список с фильтрацией по date_from, date_to, status[], tag_ids[]
- `GET /api/v1/tasks/:id` — получение по ID
- `PATCH /api/v1/tasks/:id` — редактирование
- `DELETE /api/v1/tasks/:id` — удаление

### 2. Теги

Связь many-to-many (Task <-> Tag через TaskTag).

Три системных тега создаются через seeds и защищены от удаления/изменения (403): "отчетность", "операции", "звонок".

Эндпоинты:
- `GET /api/v1/tags` — список
- `POST /api/v1/tags` — создание
- `PATCH /api/v1/tags/:id` — редактирование 
- `DELETE /api/v1/tags/:id` — удаление
- `POST /api/v1/tasks/:task_id/tags` — привязать тег
- `DELETE /api/v1/tasks/:task_id/tags/:id` — отвязать тег

### 3. Повторяющиеся задачи

Задача может быть повторяющейся (recurring=true). В этом случае у неё есть starts_on, ends_on (может быть NULL — бессрочная) и правило повторения (RecurrenceRule):

Типы правил:
- **daily** — каждый N-й день (interval)
- **monthly** — конкретное число месяца (day_of_month, 1-31)
- **specific_dates** — массив конкретных дат
- **even_odd** — только чётные или нечётные числа месяца

#### Как это работает — календарная таблица

В БД будет таблица `calendar_dates` — предзаполненная на 10 лет (2025-2035, ~3650 строк). Каждая строка — одна дата с атрибутами: day_of_month, day_of_week, is_even_day, month, year.

Вхождения повторяющихся задач не хранятся в бд заранее. Они вычисляются через SQL JOIN таблицы `calendar_dates` с `recurrence_rules` для запрошенного диапазона дат чтобы решить проблему бесконечности

При запросе `GET /tasks?date_from=...&date_to=...`:
1. Разовые задачи берутся из tasks (WHERE due_date BETWEEN ...)
2. Повторяющиеся — через JOIN calendar_dates + recurrence_rules
3. Результаты объединяются в единый список

#### Состояние конкретного экземпляра

Таблица `task_occurrences` — создаётся запись только когда пользователь взаимодействует с конкретным днём повторяющейся задачи (отметил выполненной, изменил, отменил). При выборке: если запись есть — берём её данные, если нет — виртуальное вхождение со статусом pending.

Эндпоинты:
- `PATCH /api/v1/tasks/:id/occurrences/:date` — изменить/выполнить конкретный день
- `DELETE /api/v1/tasks/:id/occurrences/:date` — отменить конкретный день (cancelled: true)

В occurrence можно переопределить title и description — это позволяет «оторвать» один экземпляр от шаблона.

## Схема БД

```
calendar_dates: date(PK), day_of_month, day_of_week, is_even_day, month, year

tasks: id, title, description, due_date, status, recurring, starts_on, ends_on, timestamps

recurrence_rules: id, task_id(FK unique), rule_type, interval, day_of_month, specific_dates(date[]), even_odd

task_occurrences: id, task_id(FK), occurrence_date, status, title, description, cancelled, timestamps
  — UNIQUE INDEX (task_id, occurrence_date)

tags: id, name(unique), system(bool)

task_tags: task_id(FK), tag_id(FK)
  — UNIQUE INDEX (task_id, tag_id)
```

## Документация кода

Все публичные методы в сервисах, контрактах, query objects и контроллерах должны быть задокументированы в формате YARD:

```ruby
# @param params [Hash] параметры для создания задачи
# @option params [String] :title название задачи
# @option params [String] :description описание задачи
# @option params [Date] :due_date дата выполнения
# @return [Dry::Monads::Result] Success(Task) или Failure(Hash)
```

## Тесты

Покрыть RSpec-тестами: model specs, service specs, query specs, request specs. Swagger-документация генерируется через rswag-specs.


