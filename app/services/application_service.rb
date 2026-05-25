# frozen_string_literal: true

# Base service class — includes Dry::Monads Result DSL for all subclasses.
class ApplicationService
  include Dry::Monads[:result]
end
