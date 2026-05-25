# frozen_string_literal: true

module TaskOccurrences
  # Cancels a single occurrence of a recurring task on a given date.
  #
  # Finds or creates a TaskOccurrence row and sets cancelled: true.
  # The occurrence inherits task fields (status, title, description) when no
  # existing overrides are present, so the record is self-contained.
  class CancelService < ApplicationService
    # @param task [Task] the parent task
    # @param date [Date] the occurrence date to cancel
    # @return [Dry::Monads::Result] Success(TaskOccurrence) or Failure(...)
    def call(task, date)
      unless OccurrenceDateValidator.valid?(task, date)
        return Failure({ code: :validation_error, errors: { date: [ "is not a valid occurrence date for this task" ] } })
      end

      occurrence = task.task_occurrences.find_or_initialize_by(occurrence_date: date)
      occurrence.assign_attributes(
        cancelled:   true,
        status:      occurrence.status.presence      || task.status,
        title:       occurrence.title.presence       || task.title,
        description: occurrence.description.presence || task.description
      )

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
