# frozen_string_literal: true

module TaskOccurrences
  # Creates or updates a TaskOccurrence for a given task + date, merging any
  # provided override attributes (status, title, description).
  #
  # Calling this service marks the occurrence as not-cancelled (cancelled: false).
  class UpsertService < ApplicationService
    # @param task [Task]   the parent task
    # @param date [Date]   the occurrence date
    # @param params [Hash] override attributes (:status, :title, :description)
    # @return [Dry::Monads::Result] Success(TaskOccurrence) or Failure(...)
    def call(task, date, params = {})
      unless OccurrenceDateValidator.valid?(task, date)
        return Failure({ code: :validation_error, errors: { date: [ "is not a valid occurrence date for this task" ] } })
      end

      occurrence = task.task_occurrences.find_or_initialize_by(occurrence_date: date)
      occurrence.assign_attributes(params.merge(cancelled: false))

      if occurrence.save
        Success(occurrence)
      else
        Failure({ code: :unprocessable_entity, errors: occurrence.errors.messages })
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end
end
