require "rails_helper"

RSpec.describe TaskOccurrences::CancelService do
  subject(:service) { described_class.new }

  let(:task) { create(:task, :recurring, status: "pending") }
  let(:date) { Date.new(2026, 6, 3) }

  describe "#call" do
    context "when no prior override exists" do
      it "creates a new cancelled TaskOccurrence" do
        expect {
          service.call(task, date)
        }.to change(TaskOccurrence, :count).by(1)
      end

      it "returns Success with cancelled=true" do
        result = service.call(task, date)
        expect(result).to be_success
        expect(result.value!.cancelled).to be true
      end

      it "inherits task status, title and description" do
        result = service.call(task, date)
        occurrence = result.value!
        expect(occurrence.status).to eq(task.status)
        expect(occurrence.title).to eq(task.title)
        expect(occurrence.description).to eq(task.description)
      end
    end

    context "when an override occurrence already exists" do
      let!(:existing) do
        create(:task_occurrence, task: task, occurrence_date: date,
               status: "in_progress", title: "Custom title")
      end

      it "sets cancelled on the existing record" do
        service.call(task, date)
        expect(existing.reload.cancelled).to be true
      end

      it "preserves existing overridden fields" do
        service.call(task, date)
        expect(existing.reload.status).to eq("in_progress")
        expect(existing.reload.title).to eq("Custom title")
      end

      it "does not create a new record" do
        expect { service.call(task, date) }.not_to change(TaskOccurrence, :count)
      end
    end
  end
end
