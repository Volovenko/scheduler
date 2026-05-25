# == Schema Information
#
# Table name: task_tags
#
#  id      :bigint           not null, primary key
#  tag_id  :bigint           not null
#  task_id :bigint           not null
#
# Indexes
#
#  index_task_tags_on_tag_id              (tag_id)
#  index_task_tags_on_task_id             (task_id)
#  index_task_tags_on_task_id_and_tag_id  (task_id,tag_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tag_id => tags.id)
#  fk_rails_...  (task_id => tasks.id)
#
require "rails_helper"

RSpec.describe TaskTag, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:task) }
    it { is_expected.to belong_to(:tag) }
  end

  describe "uniqueness" do
    let(:task) { create(:task) }
    let(:tag)  { create(:tag) }

    it "prevents duplicate task-tag pairs" do
      TaskTag.create!(task: task, tag: tag)
      duplicate = TaskTag.new(task: task, tag: tag)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:task_id]).to be_present
    end
  end
end
