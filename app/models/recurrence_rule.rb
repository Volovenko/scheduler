# frozen_string_literal: true

# == Schema Information
#
# Table name: recurrence_rules
#
#  id             :bigint           not null, primary key
#  day_of_month   :integer
#  even_odd       :string
#  interval       :integer
#  rule_type      :string           not null
#  specific_dates :date             default([]), is an Array
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  task_id        :bigint           not null
#
# Indexes
#
#  index_recurrence_rules_on_task_id  (task_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (task_id => tasks.id)
#
class RecurrenceRule < ApplicationRecord
  RULE_TYPES  = %w[daily monthly specific_dates even_odd].freeze
  EVEN_ODD    = %w[even odd].freeze

  belongs_to :task

  validates :rule_type, inclusion: { in: RULE_TYPES }
  validates :interval,      presence: true, numericality: { only_integer: true, greater_than: 0 },
                             if: -> { rule_type == "daily" }
  validates :day_of_month,  presence: true, numericality: { only_integer: true, in: 1..31 },
                             if: -> { rule_type == "monthly" }
  validates :specific_dates, presence: true,
                             if: -> { rule_type == "specific_dates" }
  validates :even_odd,      inclusion: { in: EVEN_ODD },
                             if: -> { rule_type == "even_odd" }
end
