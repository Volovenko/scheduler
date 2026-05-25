require "rails_helper"

RSpec.describe TasksQuery do
  # Only one-time tasks — no recurring tasks in this spec to keep the results deterministic.
  let!(:task_today)     { create(:task, due_date: Date.current,       status: "pending") }
  let!(:task_tomorrow)  { create(:task, due_date: Date.current + 1,   status: "in_progress") }
  let!(:task_last_week) { create(:task, due_date: Date.current - 7,   status: "completed") }

  subject(:query) { described_class.new }

  describe "#call" do
    context "without filters" do
      it "returns all tasks ordered by due_date" do
        result = query.call
        expect(result).to eq([task_last_week, task_today, task_tomorrow])
      end
    end

    context "with date_from filter" do
      it "excludes tasks before the date" do
        result = query.call(date_from: Date.current)
        expect(result).to include(task_today, task_tomorrow)
        expect(result).not_to include(task_last_week)
      end
    end

    context "with date_to filter" do
      it "excludes tasks after the date" do
        result = query.call(date_to: Date.current)
        expect(result).to include(task_today, task_last_week)
        expect(result).not_to include(task_tomorrow)
      end
    end

    context "with date range" do
      it "returns only tasks in range" do
        result = query.call(date_from: Date.current, date_to: Date.current)
        expect(result).to contain_exactly(task_today)
      end
    end

    context "with status filter" do
      it "filters by single status" do
        result = query.call(status: ["pending"])
        expect(result).to contain_exactly(task_today)
      end

      it "filters by multiple statuses" do
        result = query.call(status: %w[pending in_progress])
        expect(result).to include(task_today, task_tomorrow)
        expect(result).not_to include(task_last_week)
      end
    end

    context "with tag_ids filter" do
      let!(:tag_a) { create(:tag) }
      let!(:tag_b) { create(:tag) }
      before do
        task_today.tags    << tag_a
        task_tomorrow.tags << tag_a
        task_tomorrow.tags << tag_b
      end

      it "returns tasks that have the given tag" do
        result = query.call(tag_ids: [tag_a.id])
        expect(result).to include(task_today, task_tomorrow)
        expect(result).not_to include(task_last_week)
      end

      it "returns tasks that have ALL given tags (AND logic)" do
        result = query.call(tag_ids: [tag_a.id, tag_b.id])
        expect(result).to contain_exactly(task_tomorrow)
      end
    end

    context "with combined filters" do
      it "applies all filters together" do
        result = query.call(date_from: Date.current, status: ["pending"])
        expect(result).to contain_exactly(task_today)
      end
    end
  end
end
