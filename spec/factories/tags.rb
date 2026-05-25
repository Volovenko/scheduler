# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  system     :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tags_on_name  (name) UNIQUE
#
FactoryBot.define do
  factory :tag do
    name   { Faker::Lorem.unique.word }
    system { false }

    trait :system do
      name   { Tag::SYSTEM_NAMES.sample }
      system { true }
    end
  end
end
