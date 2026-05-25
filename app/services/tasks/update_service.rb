# frozen_string_literal: true

module Tasks
  # Updates an existing Task (and its RecurrenceRule) after validating input.
  #
  # If :recurrence_rule is present in params, the existing rule is updated or a
  # new one is created inside the same transaction.
  class UpdateService < ApplicationService
    # @param task [Task] the task record to update
    # @param params [Hash] attributes to update (partial update supported)
    # @return [Dry::Monads::Result] Success(Task) or Failure({ code:, errors: })
    def call(task, params)
      validation = TaskContract.new.call(params)
      return Failure({ code: :validation_error, errors: validation.errors.to_h }) if validation.failure?

      data      = validation.to_h
      rule_data = data.delete(:recurrence_rule)

      result = nil

      Task.transaction do
        unless task.update(data)
          result = Failure({ code: :unprocessable_entity, errors: task.errors.messages })
          raise ActiveRecord::Rollback
        end

        if rule_data.present?
          rule = task.recurrence_rule || task.build_recurrence_rule
          unless rule.update(rule_data)
            result = Failure({ code: :unprocessable_entity, errors: rule.errors.messages })
            raise ActiveRecord::Rollback
          end
        end

        result = Success(task)
      end

      result
    end
  end
end
