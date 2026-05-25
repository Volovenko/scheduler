class CreateCalendarDates < ActiveRecord::Migration[8.1]
  def up
    create_table :calendar_dates, id: false do |t|
      t.date    :date,         primary_key: true, null: false
      t.integer :day_of_month, null: false
      t.integer :day_of_week,  null: false  # 0=Sunday … 6=Saturday
      t.boolean :is_even_day,  null: false
      t.integer :month,        null: false
      t.integer :year,         null: false
    end

    add_index :calendar_dates, %i[year month], name: "index_calendar_dates_on_year_month"

    # Pre-populate 2025–2035 (~3 653 rows) using raw SQL to avoid model dependency
    execute <<~SQL
      INSERT INTO calendar_dates (date, day_of_month, day_of_week, is_even_day, month, year)
      SELECT
        d::date,
        EXTRACT(DAY FROM d)::integer,
        EXTRACT(ISODOW FROM d)::integer % 7,
        (EXTRACT(DAY FROM d)::integer % 2 = 0),
        EXTRACT(MONTH FROM d)::integer,
        EXTRACT(YEAR FROM d)::integer
      FROM generate_series('2025-01-01'::date, '2035-12-31'::date, '1 day'::interval) AS d
    SQL
  end

  def down
    drop_table :calendar_dates
  end
end
