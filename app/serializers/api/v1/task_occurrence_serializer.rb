# frozen_string_literal: true

module Api
  module V1
    # Serializes a TaskOccurrence record to JSON.
    class TaskOccurrenceSerializer < ActiveModel::Serializer
      attributes :task_id, :occurrence_date, :status, :title, :description,
                 :cancelled, :created_at, :updated_at
    end
  end
end
