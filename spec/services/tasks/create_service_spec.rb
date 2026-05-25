require "rails_helper"

RSpec.describe Tasks::CreateService do
  subject(:service) { described_class.new }

  let(:valid_params) do
    { title: "Подготовить отчёт", due_date: Date.current + 3, status: "pending", recurring: false }
  end

  describe "#call" do
    context "with valid params" do
      it "returns Success with the created task" do
        result = service.call(valid_params)
        expect(result).to be_success
        expect(result.value!).to be_a(Task)
        expect(result.value!.title).to eq("Подготовить отчёт")
      end

      it "persists the task" do
        expect { service.call(valid_params) }.to change(Task, :count).by(1)
      end
    end

    context "with missing title" do
      it "returns Failure with validation errors" do
        result = service.call(valid_params.merge(title: ""))
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:validation_error)
        expect(result.failure[:errors]).to have_key(:title)
      end
    end

    context "with invalid status" do
      it "returns Failure" do
        result = service.call(valid_params.merge(status: "unknown"))
        expect(result).to be_failure
        expect(result.failure[:errors]).to have_key(:status)
      end
    end

    context "when recurring without starts_on" do
      it "returns Failure" do
        params = { title: "Daily check", recurring: true, starts_on: nil }
        result = service.call(params)
        expect(result).to be_failure
        expect(result.failure[:errors]).to have_key(:starts_on)
      end
    end
  end
end
