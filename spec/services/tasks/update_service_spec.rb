require "rails_helper"

RSpec.describe Tasks::UpdateService do
  subject(:service) { described_class.new }

  let!(:task) { create(:task, title: "Old title", status: "pending") }

  describe "#call" do
    context "with valid params" do
      it "returns Success with the updated task" do
        result = service.call(task, { title: "New title" })
        expect(result).to be_success
        expect(result.value!.title).to eq("New title")
      end

      it "persists the change" do
        service.call(task, { status: "in_progress" })
        expect(task.reload.status).to eq("in_progress")
      end
    end

    context "with blank title" do
      it "returns Failure" do
        result = service.call(task, { title: "" })
        expect(result).to be_failure
        expect(result.failure[:errors]).to have_key(:title)
      end
    end

    context "with invalid status" do
      it "returns Failure" do
        result = service.call(task, { status: "bogus" })
        expect(result).to be_failure
      end
    end
  end
end
