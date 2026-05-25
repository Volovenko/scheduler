# frozen_string_literal: true

# Value object representing a single computed occurrence of a recurring task.
#
# Built by RecurringTasksQuery from a SQL JOIN of tasks + recurrence_rules + calendar_dates.
# Not persisted — exists only in the context of a list response.
#
# Due_date is set to the occurrence date so the API response is uniform
# with one-time tasks (clients use due_date for display in both cases).
class RecurringOccurrence
  include ActiveModel::Model
  include ActiveModel::Serialization

  attr_accessor :id, :title, :description, :due_date, :status,
                :recurring, :starts_on, :ends_on,
                :created_at, :updated_at,
                :tags, :recurrence_rule

  def self.model_name
    ActiveModel::Name.new(self, nil, "RecurringOccurrence")
  end
end
