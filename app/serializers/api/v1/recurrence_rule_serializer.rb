# frozen_string_literal: true

module Api
  module V1
    # Serializes a RecurrenceRule record to JSON.
    class RecurrenceRuleSerializer < ActiveModel::Serializer
      attributes :id, :rule_type, :interval, :day_of_month, :specific_dates, :even_odd
    end
  end
end
