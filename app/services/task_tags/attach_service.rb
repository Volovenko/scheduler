# frozen_string_literal: true

module TaskTags
  # Attaches an existing Tag to a Task (idempotent — does nothing if already attached).
  class AttachService < ApplicationService
    # @param task [Task] the target task
    # @param tag [Tag] the tag to attach
    # @return [Dry::Monads::Result] Success(TaskTag) or Failure({ code:, errors: })
    def call(task, tag)
      task_tag = TaskTag.find_or_initialize_by(task: task, tag: tag)

      if task_tag.persisted? || task_tag.save
        Success(task_tag)
      else
        Failure({ code: :unprocessable_entity, errors: task_tag.errors.messages })
      end
    end
  end
end
