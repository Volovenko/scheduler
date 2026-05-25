# Справочная таблица calendar_dates — заполняется если пуста (на случай db:schema:load)
if CalendarDate.count.zero?
  ActiveRecord::Base.connection.execute(<<~SQL)
    INSERT INTO calendar_dates (date, day_of_month, day_of_week, is_even_day, month, year)
    SELECT
      d::date,
      EXTRACT(DAY FROM d)::integer,
      EXTRACT(ISODOW FROM d)::integer % 7,
      (EXTRACT(DAY FROM d)::integer % 2 = 0),
      EXTRACT(MONTH FROM d)::integer,
      EXTRACT(YEAR FROM d)::integer
    FROM generate_series('2025-01-01'::date, '2035-12-31'::date, '1 day'::interval) AS d
    ON CONFLICT DO NOTHING
  SQL
  puts "Calendar dates seeded: #{CalendarDate.count} rows"
else
  puts "Calendar dates already present: #{CalendarDate.count} rows"
end

# Системные теги — создаются один раз, защищены от изменения и удаления через API.
Tag::SYSTEM_NAMES.each do |name|
  Tag.find_or_create_by!(name: name) { |t| t.system = true }
end

puts "System tags seeded: #{Tag::SYSTEM_NAMES.join(', ')}"

# Пользовательские теги
custom_tags = %w[срочное инвентаризация лаборатория].map do |name|
  Tag.find_or_create_by!(name: name)
end

puts "Custom tags seeded: #{custom_tags.map(&:name).join(', ')}"

# --- Демонстрационные задачи ---

# Разовые задачи
task1 = Task.find_or_create_by!(title: "Связаться с пациентом Ивановым") do |t|
  t.description = "Уточнить результаты анализов"
  t.due_date = Date.current + 3
  t.recurring = false
end

task2 = Task.find_or_create_by!(title: "Подготовить отчёт за месяц") do |t|
  t.due_date = Date.current + 7
  t.recurring = false
end

# Привязка тегов к разовым задачам
report_tag = Tag.find_by!(name: "отчетность")
call_tag   = Tag.find_by!(name: "звонок")
TaskTag.find_or_create_by!(task: task1, tag: call_tag)
TaskTag.find_or_create_by!(task: task2, tag: report_tag)

puts "One-time tasks seeded: #{task1.id}, #{task2.id}"

# Повторяющаяся задача — ежедневный обход (на 6 месяцев)
daily_task = Task.find_or_create_by!(title: "Утренний обход пациентов") do |t|
  t.description = "Обход палат 1-10"
  t.recurring = true
  t.starts_on = Date.current
  t.ends_on = Date.current + 6.months
end
daily_task.recurrence_rule || daily_task.create_recurrence_rule!(rule_type: "daily", interval: 1)
TaskTag.find_or_create_by!(task: daily_task, tag: Tag.find_by!(name: "операции"))

puts "Daily recurring task seeded: id=#{daily_task.id} (#{daily_task.starts_on}..#{daily_task.ends_on})"

# Повторяющаяся задача — отчётность по чётным дням (бессрочная)
even_task = Task.find_or_create_by!(title: "Формирование отчётности") do |t|
  t.description = "Сводка по приёмам за день"
  t.recurring = true
  t.starts_on = Date.current
end
even_task.recurrence_rule || even_task.create_recurrence_rule!(rule_type: "even_odd", even_odd: "even")
TaskTag.find_or_create_by!(task: even_task, tag: report_tag)

puts "Even-days recurring task seeded: id=#{even_task.id} (starts #{even_task.starts_on}, no end)"

# Повторяющаяся задача — ежемесячная инвентаризация на 15-е число
monthly_task = Task.find_or_create_by!(title: "Инвентаризация расходных материалов") do |t|
  t.recurring = true
  t.starts_on = Date.current
  t.ends_on = Date.current + 1.year
end
monthly_task.recurrence_rule || monthly_task.create_recurrence_rule!(rule_type: "monthly", day_of_month: 15)
TaskTag.find_or_create_by!(task: monthly_task, tag: custom_tags.find { |t| t.name == "инвентаризация" })

puts "Monthly recurring task seeded: id=#{monthly_task.id} (day 15)"

# Повторяющаяся задача — обзвон пациентов на конкретные даты
specific_dates = [ Date.current + 5, Date.current + 12, Date.current + 19, Date.current + 26 ]
specific_task = Task.find_or_create_by!(title: "Обзвон пациентов после выписки") do |t|
  t.description = "Контрольный звонок через неделю после выписки"
  t.recurring = true
  t.starts_on = specific_dates.first
  t.ends_on = specific_dates.last
end
specific_task.recurrence_rule || specific_task.create_recurrence_rule!(
  rule_type: "specific_dates",
  specific_dates: specific_dates
)
TaskTag.find_or_create_by!(task: specific_task, tag: call_tag)

puts "Specific-dates recurring task seeded: id=#{specific_task.id} (#{specific_dates.join(', ')})"

puts "\n--- Seed complete ---"
puts "Try: curl http://localhost:3000/api/v1/tasks?date_from=#{Date.current}&date_to=#{Date.current + 30}"
