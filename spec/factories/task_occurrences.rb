# == Schema Information
#
# Table name: task_occurrences
#
#  id              :bigint           not null, primary key
#  cancelled       :boolean          default(FALSE), not null
#  description     :text
#  occurrence_date :date             not null
#  status          :string
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  task_id         :bigint           not null
#
# Indexes
#
#  index_task_occurrences_on_task_id                      (task_id)
#  index_task_occurrences_on_task_id_and_occurrence_date  (task_id,occurrence_date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (task_id => tasks.id)
#
FactoryBot.define do
  factory :task_occurrence do
    association :task, factory: %i[task recurring]
    occurrence_date { Date.current }
    status          { nil }
    title           { nil }
    description     { nil }
    cancelled       { false }

    trait :cancelled do
      cancelled { true }
    end

    trait :with_overrides do
      status      { "completed" }
      title       { "Override title" }
      description { "Override description" }
    end
  end
end
