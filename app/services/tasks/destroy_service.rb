# frozen_string_literal: true

module Tasks
  # Deletes a Task record.
  class DestroyService < ApplicationService
    # @param task [Task] the task to delete
    # @return [Dry::Monads::Result] Success(true) or Failure({ code:, errors: })
    def call(task)
      if task.destroy
        Success(true)
      else
        Failure({ code: :unprocessable_entity, errors: task.errors.messages })
      end
    end
  end
end
