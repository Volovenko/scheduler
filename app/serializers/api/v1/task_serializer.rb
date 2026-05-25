# frozen_string_literal: true

module Api
  module V1
    # Serializes a Task record to JSON for API responses.
    class TaskSerializer < ActiveModel::Serializer
      attributes :id, :title, :description, :due_date, :status,
                 :recurring, :starts_on, :ends_on,
                 :created_at, :updated_at

      has_many :tags, serializer: Api::V1::TagSerializer
      has_one  :recurrence_rule, serializer: Api::V1::RecurrenceRuleSerializer
    end
  end
end
