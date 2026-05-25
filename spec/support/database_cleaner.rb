RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    # Exclude calendar_dates — it is static reference data (2025-2035) seeded by migration.
    DatabaseCleaner.clean_with(:truncation, except: %w[calendar_dates])

    # Re-populate if empty (e.g. after db:schema:load which does not run migration data).
    unless CalendarDate.exists?
      rows = (Date.new(2025, 1, 1)..Date.new(2035, 12, 31)).map do |d|
        { date: d, day_of_month: d.day, day_of_week: d.wday,
          is_even_day: d.day.even?, month: d.month, year: d.year }
      end
      rows.each_slice(500) { |batch| CalendarDate.insert_all!(batch) }
    end
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end
end
