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
require "rails_helper"

RSpec.describe TaskOccurrence, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:task) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:occurrence_date) }

    it "validates status inclusion when present" do
      occurrence = build(:task_occurrence, status: "invalid_status")
      expect(occurrence).not_to be_valid
      expect(occurrence.errors[:status]).to be_present
    end

    it "allows nil status" do
      occurrence = build(:task_occurrence, status: nil)
      expect(occurrence).to be_valid
    end

    it "enforces uniqueness of task_id scoped to occurrence_date" do
      task      = create(:task, :recurring)
      _existing = create(:task_occurrence, task: task, occurrence_date: Date.current)
      duplicate = build(:task_occurrence, task: task, occurrence_date: Date.current)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:task_id]).to be_present
    end
  end
end
