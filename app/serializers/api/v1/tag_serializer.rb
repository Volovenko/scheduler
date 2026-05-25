# frozen_string_literal: true

module Api
  module V1
    # Serializes a Tag record to JSON for API responses.
    class TagSerializer < ActiveModel::Serializer
      attributes :id, :name, :system
    end
  end
end
