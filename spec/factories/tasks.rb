# == Schema Information
#
# Table name: tasks
#
#  id          :bigint           not null, primary key
#  description :text
#  due_date    :date
#  ends_on     :date
#  recurring   :boolean          default(FALSE), not null
#  starts_on   :date
#  status      :string           default("pending"), not null
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_tasks_on_due_date  (due_date)
#  index_tasks_on_status    (status)
#
FactoryBot.define do
  factory :task do
    title       { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    due_date    { Faker::Date.forward(days: 30) }
    status      { "pending" }
    recurring   { false }

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :recurring do
      recurring  { true }
      due_date   { nil }
      starts_on  { Date.current }
      ends_on    { nil }
    end
  end
end
