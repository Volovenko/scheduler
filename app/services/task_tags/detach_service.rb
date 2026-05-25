# frozen_string_literal: true

module TaskTags
  # Detaches a Tag from a Task. Returns not_found if the link doesn't exist.
  class DetachService < ApplicationService
    # @param task [Task] the target task
    # @param tag [Tag] the tag to detach
    # @return [Dry::Monads::Result] Success(true) or Failure({ code:, errors: })
    def call(task, tag)
      task_tag = TaskTag.find_by(task: task, tag: tag)

      unless task_tag
        return Failure({ code: :not_found, errors: { base: ["tag is not attached to this task"] } })
      end

      if task_tag.destroy
        Success(true)
      else
        Failure({ code: :unprocessable_entity, errors: task_tag.errors.messages })
      end
    end
  end
end
