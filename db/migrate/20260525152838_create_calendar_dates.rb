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

    # Pre-populate 2025–2035 (~3 653 rows)
    rows = []
    (Date.new(2025, 1, 1)..Date.new(2035, 12, 31)).each do |d|
      rows << {
        date:         d,
        day_of_month: d.day,
        day_of_week:  d.wday,
        is_even_day:  d.day.even?,
        month:        d.month,
        year:         d.year
      }
    end

    rows.each_slice(500) { |batch| CalendarDate.insert_all!(batch) }
  end

  def down
    drop_table :calendar_dates
  end
end
