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
require "rails_helper"

RSpec.describe Task, type: :model do
  subject(:task) { build(:task) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Task::STATUSES) }

    context "when one-time task" do
      it "requires due_date" do
        task = build(:task, recurring: false, due_date: nil)
        expect(task).not_to be_valid
        expect(task.errors[:due_date]).to include("can't be blank")
      end
    end

    context "when recurring task" do
      it "requires starts_on" do
        task = build(:task, :recurring, starts_on: nil)
        expect(task).not_to be_valid
        expect(task.errors[:starts_on]).to include("can't be blank")
      end

      it "validates ends_on is after starts_on" do
        task = build(:task, :recurring, starts_on: Date.current, ends_on: Date.current - 1)
        expect(task).not_to be_valid
        expect(task.errors[:ends_on]).to be_present
      end

      it "is valid without ends_on (open-ended)" do
        task = build(:task, :recurring, ends_on: nil)
        expect(task).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:pending_task)   { create(:task, status: "pending",     due_date: Date.current) }
    let!(:done_task)      { create(:task, :completed,            due_date: Date.current + 1) }
    let!(:old_task)       { create(:task, due_date: Date.current - 10) }

    describe ".by_status" do
      it "filters by a single status" do
        expect(described_class.by_status("pending")).to include(pending_task)
        expect(described_class.by_status("pending")).not_to include(done_task)
      end

      it "filters by multiple statuses" do
        expect(described_class.by_status(%w[pending completed])).to include(pending_task, done_task)
      end
    end

    describe ".by_date_range" do
      it "returns tasks within the range" do
        expect(described_class.by_date_range(Date.current, Date.current + 5)).to include(pending_task, done_task)
        expect(described_class.by_date_range(Date.current, Date.current + 5)).not_to include(old_task)
      end
    end
  end
end
