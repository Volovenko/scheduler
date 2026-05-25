# frozen_string_literal: true

module Tags
  # Deletes a custom Tag. System tags are protected and return a Failure.
  class DestroyService < ApplicationService
    # @param tag [Tag] the tag to delete
    # @return [Dry::Monads::Result] Success(true) or Failure({ code:, errors: })
    def call(tag)
      return Failure({ code: :forbidden, errors: { base: [ "system tags cannot be deleted" ] } }) if tag.system?

      if tag.destroy
        Success(true)
      else
        Failure({ code: :unprocessable_entity, errors: tag.errors.messages })
      end
    end
  end
end
