# frozen_string_literal: true

module TaskOccurrences
  # Checks whether a given date is a valid occurrence for a recurring task
  # based on its recurrence rule, starts_on, and ends_on boundaries.
  class OccurrenceDateValidator
    # @param task [Task] a recurring task with a loaded recurrence_rule
    # @param date [Date] the candidate occurrence date
    # @return [Boolean]
    def self.valid?(task, date)
      return false unless task.recurring?

      rule = task.recurrence_rule
      return false unless rule
      return false if date < task.starts_on
      return false if task.ends_on.present? && date > task.ends_on

      case rule.rule_type
      when "daily"
        (date - task.starts_on).to_i % rule.interval == 0
      when "monthly"
        date.day == rule.day_of_month
      when "specific_dates"
        rule.specific_dates.include?(date)
      when "even_odd"
        rule.even_odd == "even" ? date.day.even? : date.day.odd?
      else
        false
      end
    end
  end
end
