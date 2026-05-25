# frozen_string_literal: true

module Tags
  # Creates a new custom Tag after validating input.
  class CreateService < ApplicationService
    # @param params [Hash] tag attributes
    # @option params [String] :name tag name (required, unique)
    # @return [Dry::Monads::Result] Success(Tag) or Failure({ code:, errors: })
    def call(params)
      validation = TagContract.new.call(params)
      return Failure({ code: :validation_error, errors: validation.errors.to_h }) if validation.failure?

      tag = Tag.new(validation.to_h.merge(system: false))
      if tag.save
        Success(tag)
      else
        Failure({ code: :unprocessable_entity, errors: tag.errors.messages })
      end
    end
  end
end
