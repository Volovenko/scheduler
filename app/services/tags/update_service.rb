# frozen_string_literal: true

module Tags
  # Updates a Tag name. System tags are protected and return a Failure.
  class UpdateService < ApplicationService
    # @param tag [Tag] the tag to update
    # @param params [Hash] attributes to update
    # @option params [String] :name new tag name
    # @return [Dry::Monads::Result] Success(Tag) or Failure({ code:, errors: })
    def call(tag, params)
      return Failure({ code: :forbidden, errors: { base: ["system tags cannot be modified"] } }) if tag.system?

      validation = TagContract.new.call(params)
      return Failure({ code: :validation_error, errors: validation.errors.to_h }) if validation.failure?

      if tag.update(validation.to_h)
        Success(tag)
      else
        Failure({ code: :unprocessable_entity, errors: tag.errors.messages })
      end
    end
  end
end
