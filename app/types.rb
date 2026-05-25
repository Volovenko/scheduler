# frozen_string_literal: true

module Types
  include Dry.Types()

  # Strict string enum for task statuses
  TaskStatus = Types::Strict::String.enum("pending", "in_progress", "completed", "cancelled")

  # Strict string enum for recurrence rule types
  RecurrenceRuleType = Types::Strict::String.enum("daily", "monthly", "specific_dates", "even_odd")

  # Strict string enum for even/odd rule
  EvenOdd = Types::Strict::String.enum("even", "odd")
end
