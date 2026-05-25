require "rails_helper"

RSpec.describe TaskOccurrences::UpsertService do
  subject(:service) { described_class.new }

  let(:task) do
    t = create(:task, :recurring, starts_on: Date.new(2026, 6, 1))
    create(:recurrence_rule, :daily, task: t, interval: 1)
    t
  end
  let(:date) { Date.new(2026, 6, 2) }

  describe "#call" do
    context "when no occurrence exists for the date" do
      it "creates a new TaskOccurrence" do
        expect {
          service.call(task, date, { status: "completed" })
        }.to change(TaskOccurrence, :count).by(1)
      end

      it "returns Success with the occurrence" do
        result = service.call(task, date, { status: "in_progress" })
        expect(result).to be_success
        expect(result.value!).to be_a(TaskOccurrence)
        expect(result.value!.status).to eq("in_progress")
        expect(result.value!.cancelled).to be false
      end

      it "sets cancelled to false regardless of params" do
        result = service.call(task, date, {})
        expect(result.value!.cancelled).to be false
      end
    end

    context "when an occurrence already exists" do
      let!(:existing) { create(:task_occurrence, task: task, occurrence_date: date, status: "pending") }

      it "does not create a new record" do
        expect {
          service.call(task, date, { status: "completed" })
        }.not_to change(TaskOccurrence, :count)
      end

      it "updates the existing occurrence" do
        service.call(task, date, { status: "completed", title: "Updated" })
        expect(existing.reload.status).to eq("completed")
        expect(existing.reload.title).to eq("Updated")
      end

      it "marks the occurrence as not-cancelled" do
        existing.update!(cancelled: true)
        service.call(task, date, {})
        expect(existing.reload.cancelled).to be false
      end
    end

    context "with invalid status" do
      it "returns Failure" do
        result = service.call(task, date, { status: "nonexistent" })
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:unprocessable_entity)
      end
    end
  end
end
