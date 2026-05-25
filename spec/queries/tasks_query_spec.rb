require "rails_helper"

RSpec.describe TasksQuery do
  # Only one-time tasks — no recurring tasks in this spec to keep the results deterministic.
  let!(:task_today)     { create(:task, due_date: Date.current,       status: "pending") }
  let!(:task_tomorrow)  { create(:task, due_date: Date.current + 1,   status: "in_progress") }
  let!(:task_last_week) { create(:task, due_date: Date.current - 7,   status: "completed") }

  subject(:query) { described_class.new }

  def items(params = {})
    query.call(params)[:items]
  end

  describe "#call" do
    context "without filters" do
      it "returns all tasks ordered by due_date" do
        ids = items.map(&:id)
        expect(ids).to eq([ task_last_week.id, task_today.id, task_tomorrow.id ])
      end

      it "returns total_count and pagination metadata" do
        result = query.call
        expect(result[:total_count]).to eq(3)
        expect(result[:page]).to eq(1)
        expect(result[:per_page]).to eq(25)
      end
    end

    context "with date_from filter" do
      it "excludes tasks before the date" do
        ids = items(date_from: Date.current).map(&:id)
        expect(ids).to include(task_today.id, task_tomorrow.id)
        expect(ids).not_to include(task_last_week.id)
      end
    end

    context "with date_to filter" do
      it "excludes tasks after the date" do
        ids = items(date_to: Date.current).map(&:id)
        expect(ids).to include(task_today.id, task_last_week.id)
        expect(ids).not_to include(task_tomorrow.id)
      end
    end

    context "with date range" do
      it "returns only tasks in range" do
        ids = items(date_from: Date.current, date_to: Date.current).map(&:id)
        expect(ids).to contain_exactly(task_today.id)
      end
    end

    context "with status filter" do
      it "filters by single status" do
        ids = items(status: [ "pending" ]).map(&:id)
        expect(ids).to contain_exactly(task_today.id)
      end

      it "filters by multiple statuses" do
        ids = items(status: %w[pending in_progress]).map(&:id)
        expect(ids).to include(task_today.id, task_tomorrow.id)
        expect(ids).not_to include(task_last_week.id)
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
        ids = items(tag_ids: [ tag_a.id ]).map(&:id)
        expect(ids).to include(task_today.id, task_tomorrow.id)
        expect(ids).not_to include(task_last_week.id)
      end

      it "returns tasks that have ALL given tags (AND logic)" do
        ids = items(tag_ids: [ tag_a.id, tag_b.id ]).map(&:id)
        expect(ids).to contain_exactly(task_tomorrow.id)
      end
    end

    context "with combined filters" do
      it "applies all filters together" do
        ids = items(date_from: Date.current, status: [ "pending" ]).map(&:id)
        expect(ids).to contain_exactly(task_today.id)
      end
    end
  end
end
