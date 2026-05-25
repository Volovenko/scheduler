# frozen_string_literal: true

# Validates parameters for creating and updating a Tag.
class TagContract < ApplicationContract
  params do
    optional(:name).filled(:string)
  end

  rule(:name) do
    next unless key?

    key.failure("can't be blank")          if value.strip.empty?
    key.failure("is too long (max 100)")   if value.length > 100
  end
end
