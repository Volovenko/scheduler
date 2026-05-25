# frozen_string_literal: true

# Validates parameters for a RecurrenceRule nested inside a Task.
#
# Each rule_type requires a specific set of additional fields:
#   daily          → interval (integer > 0)
#   monthly        → day_of_month (1–31)
#   specific_dates → specific_dates (array of dates, non-empty)
#   even_odd       → even_odd ('even' | 'odd')
class RecurrenceRuleContract < ApplicationContract
  RULE_TYPES = RecurrenceRule::RULE_TYPES

  params do
    required(:rule_type).filled(:string)
    optional(:interval).maybe(:integer)
    optional(:day_of_month).maybe(:integer)
    optional(:specific_dates).maybe(array[:date])
    optional(:even_odd).maybe(:string)
  end

  rule(:rule_type) do
    key.failure("must be one of: #{RULE_TYPES.join(', ')}") unless RULE_TYPES.include?(value)
  end

  rule(:interval) do
    next unless values[:rule_type] == "daily"

    key.failure("is required for daily rule")     if value.nil?
    key.failure("must be greater than 0")         if value && value < 1
  end

  rule(:day_of_month) do
    next unless values[:rule_type] == "monthly"

    key.failure("is required for monthly rule")   if value.nil?
    key.failure("must be between 1 and 31")       if value && !(1..31).cover?(value)
  end

  rule(:specific_dates) do
    next unless values[:rule_type] == "specific_dates"

    key.failure("is required for specific_dates rule") if value.nil? || value.empty?
  end

  rule(:even_odd) do
    next unless values[:rule_type] == "even_odd"

    key.failure("is required for even_odd rule")          if value.nil?
    key.failure("must be 'even' or 'odd'")                if value && !%w[even odd].include?(value)
  end
end
