# frozen_string_literal: true

# Validates parameters for creating and updating a Task.
#
# Used by Tasks::CreateService and Tasks::UpdateService before any persistence.
class TaskContract < ApplicationContract
  VALID_STATUSES = Task::STATUSES

  params do
    optional(:title).filled(:string)
    optional(:description).maybe(:string)
    optional(:due_date).maybe(:date)
    optional(:status).filled(:string)
    optional(:recurring).filled(:bool)
    optional(:starts_on).maybe(:date)
    optional(:ends_on).maybe(:date)
    optional(:recurrence_rule).maybe(:hash) do
      optional(:rule_type).filled(:string)
      optional(:interval).maybe(:integer)
      optional(:day_of_month).maybe(:integer)
      optional(:specific_dates).maybe(array[:date])
      optional(:even_odd).maybe(:string)
    end
  end

  rule(:title) do
    key.failure("can't be blank") if key? && value.strip.empty?
    key.failure("is too long (maximum 255 characters)") if key? && value.length > 255
  end

  rule(:status) do
    if key? && VALID_STATUSES.exclude?(value)
      key.failure("must be one of: #{VALID_STATUSES.join(', ')}")
    end
  end

  rule(:due_date, :recurring) do
    recurring = values[:recurring]
    if recurring == false && values[:due_date].nil? && key?(:due_date)
      key(:due_date).failure("can't be blank for a one-time task")
    end
  end

  rule(:starts_on, :recurring) do
    if values[:recurring] == true && values[:starts_on].nil?
      key(:starts_on).failure("can't be blank for a recurring task")
    end
  end

  rule(:ends_on, :starts_on) do
    starts = values[:starts_on]
    ends   = values[:ends_on]
    if starts && ends && ends <= starts
      key(:ends_on).failure("must be after starts_on")
    end
  end

  rule(:recurrence_rule, :recurring) do
    next unless values[:recurring] == true && key?(:recurrence_rule)
    next if values[:recurrence_rule].nil?

    result = RecurrenceRuleContract.new.call(values[:recurrence_rule])
    result.errors.each do |error|
      key([:recurrence_rule, error.path.first]).failure(error.text)
    end
  end
end
