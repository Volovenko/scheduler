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
FactoryBot.define do
  factory :recurrence_rule do
    association :task, factory: %i[task recurring]
    rule_type { "daily" }
    interval  { 1 }

    trait :daily do
      rule_type { "daily" }
      interval  { 1 }
    end

    trait :every_other_day do
      rule_type { "daily" }
      interval  { 2 }
    end

    trait :monthly do
      rule_type    { "monthly" }
      interval     { nil }
      day_of_month { 15 }
    end

    trait :specific_dates do
      rule_type      { "specific_dates" }
      interval       { nil }
      specific_dates { [Date.new(2026, 6, 1), Date.new(2026, 6, 15)] }
    end

    trait :even_days do
      rule_type { "even_odd" }
      interval  { nil }
      even_odd  { "even" }
    end

    trait :odd_days do
      rule_type { "even_odd" }
      interval  { nil }
      even_odd  { "odd" }
    end
  end
end
