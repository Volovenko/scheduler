# frozen_string_literal: true

# Read-only lookup table pre-populated for 2025–2035.
# Used as the join anchor for recurring task occurrence queries.
# == Schema Information
#
# Table name: calendar_dates
#
#  date         :date             not null, primary key
#  day_of_month :integer          not null
#  day_of_week  :integer          not null
#  is_even_day  :boolean          not null
#  month        :integer          not null
#  year         :integer          not null
#
# Indexes
#
#  index_calendar_dates_on_year_month  (year,month)
#
class CalendarDate < ApplicationRecord
  self.primary_key = "date"

  # No timestamps — table has no created_at/updated_at
  self.implicit_order_column = "date"
end
