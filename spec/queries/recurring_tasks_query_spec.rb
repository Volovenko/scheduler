require "rails_helper"

RSpec.describe RecurringTasksQuery do
  subject(:query) { described_class.new }

  # Use a fixed reference date that exists in calendar_dates (2025-2035).
  # starts_on = June 2, 2026 (even day), ends_on = June 30, 2026.
  let(:starts)  { Date.new(2026, 6, 2) }
  let(:ends_on) { Date.new(2026, 6, 30) }

  describe "#call — daily rule" do
    let!(:task) { create(:task, :recurring, starts_on: starts, ends_on: ends_on) }
    let!(:rule) { create(:recurrence_rule, :daily, task: task, interval: 3) }

    it "returns occurrences every 3 days starting from starts_on" do
      result = query.call
      dates  = result.map(&:due_date)

      # Day 0, 3, 6, 9, 12, 15, 18, 21, 24, 27 from starts = Jun 2
      expect(dates).to include(Date.new(2026, 6, 2))
      expect(dates).to include(Date.new(2026, 6, 5))
      expect(dates).to include(Date.new(2026, 6, 8))
      expect(dates).not_to include(Date.new(2026, 6, 3))
      expect(dates).not_to include(Date.new(2026, 6, 4))
    end

    it "returns RecurringOccurrence objects with correct task id" do
      result = query.call
      expect(result.first.id).to eq(task.id)
      expect(result.first).to be_a(RecurringOccurrence)
    end

    it "sets recurring=true on each occurrence" do
      result = query.call
      expect(result.all?(&:recurring)).to be true
    end
  end

  describe "#call — monthly rule" do
    let!(:task) do
      create(:task, :recurring,
             starts_on: Date.new(2026, 1, 1),
             ends_on:   Date.new(2026, 12, 31))
    end
    let!(:rule) { create(:recurrence_rule, :monthly, task: task, day_of_month: 15) }

    it "returns one occurrence per month on day 15" do
      result = query.call
      dates  = result.map(&:due_date)

      expect(dates).to include(Date.new(2026, 1, 15))
      expect(dates).to include(Date.new(2026, 6, 15))
      expect(dates).to include(Date.new(2026, 12, 15))
      expect(dates).not_to include(Date.new(2026, 1, 14))
    end
  end

  describe "#call — specific_dates rule" do
    let(:specific) { [ Date.new(2026, 6, 10), Date.new(2026, 6, 20) ] }
    let!(:task)    { create(:task, :recurring, starts_on: Date.new(2026, 6, 1), ends_on: Date.new(2026, 6, 30)) }
    let!(:rule)    { create(:recurrence_rule, :specific_dates, task: task, specific_dates: specific) }

    it "returns only the specific dates" do
      result = query.call
      dates  = result.map(&:due_date)
      expect(dates).to contain_exactly(*specific)
    end
  end

  describe "#call — even_odd rule" do
    let!(:task) { create(:task, :recurring, starts_on: starts, ends_on: ends_on) }
    let!(:rule) { create(:recurrence_rule, :even_days, task: task) }

    it "returns only even-day occurrences" do
      result = query.call
      result.each do |occ|
        expect(occ.due_date.day).to be_even, "expected #{occ.due_date} to be an even day"
      end
    end
  end

  describe "#call — filters" do
    let!(:task) { create(:task, :recurring, starts_on: starts, ends_on: ends_on) }
    let!(:rule) { create(:recurrence_rule, :daily, task: task, interval: 1) }

    context "date_from" do
      it "excludes occurrences before date_from" do
        result = query.call(date_from: Date.new(2026, 6, 10))
        expect(result.map(&:due_date)).to all(be >= Date.new(2026, 6, 10))
      end
    end

    context "date_to" do
      it "excludes occurrences after date_to" do
        result = query.call(date_to: Date.new(2026, 6, 5))
        expect(result.map(&:due_date)).to all(be <= Date.new(2026, 6, 5))
      end
    end

    context "status filter" do
      it "returns only matching status" do
        result = query.call(status: [ "in_progress" ])
        expect(result).to be_empty
      end

      it "returns occurrences when task status matches" do
        task.update!(status: "in_progress")
        result = query.call(status: [ "in_progress" ])
        expect(result).not_to be_empty
      end
    end

    context "tag_ids filter" do
      let!(:tag) { create(:tag) }

      it "returns empty when task does not have the tag" do
        result = query.call(tag_ids: [ tag.id ])
        expect(result).to be_empty
      end

      it "returns occurrences when task has the tag" do
        task.tags << tag
        result = query.call(tag_ids: [ tag.id ])
        expect(result).not_to be_empty
      end
    end
  end

  describe "#call — cancelled occurrences" do
    let!(:task) { create(:task, :recurring, starts_on: starts, ends_on: ends_on) }
    let!(:rule) { create(:recurrence_rule, :daily, task: task, interval: 1) }

    it "excludes dates with a cancelled task_occurrence" do
      create(:task_occurrence, :cancelled, task: task, occurrence_date: starts)
      result = query.call
      expect(result.map(&:due_date)).not_to include(starts)
    end

    it "includes dates overridden but not cancelled" do
      create(:task_occurrence, task: task, occurrence_date: starts, status: "completed", cancelled: false)
      result   = query.call
      override = result.find { |o| o.due_date == starts }
      expect(override).not_to be_nil
      expect(override.status).to eq("completed")
    end
  end

  describe "#call — tags and recurrence_rule on result" do
    let!(:tag)  { create(:tag) }
    let!(:task) { create(:task, :recurring, starts_on: starts, ends_on: starts + 1) }
    let!(:rule) { create(:recurrence_rule, :daily, task: task, interval: 1) }

    before { task.tags << tag }

    it "attaches tags to the RecurringOccurrence" do
      result = query.call
      expect(result.first.tags).to include(tag)
    end

    it "attaches recurrence_rule to the RecurringOccurrence" do
      result = query.call
      expect(result.first.recurrence_rule).to eq(rule)
    end
  end
end
