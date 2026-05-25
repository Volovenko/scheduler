# frozen_string_literal: true

module Tasks
  # Creates a new Task (and optional RecurrenceRule) after validating input.
  #
  # When params[:recurring] is true and :recurrence_rule is provided, the rule
  # is created inside the same transaction and rolled back on failure.
  class CreateService < ApplicationService
    # @param params [Hash] raw task attributes from the controller
    # @return [Dry::Monads::Result] Success(Task) or Failure({ code:, errors: })
    def call(params)
      validation = CreateTaskContract.new.call(params)
      return Failure({ code: :validation_error, errors: validation.errors.to_h }) if validation.failure?

      data      = validation.to_h
      rule_data = data.delete(:recurrence_rule)

      result = nil

      Task.transaction do
        task = Task.new(data)

        unless task.save
          result = Failure({ code: :unprocessable_entity, errors: task.errors.messages })
          raise ActiveRecord::Rollback
        end

        if task.recurring? && rule_data.present?
          rule = task.build_recurrence_rule(rule_data)
          unless rule.save
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
