require "rails_helper"

RSpec.describe Tags::CreateService do
  subject(:service) { described_class.new }

  describe "#call" do
    context "with valid params" do
      it "creates a custom tag and returns Success" do
        result = service.call({ name: "срочное" })
        expect(result).to be_success
        expect(result.value!).to be_a(Tag)
        expect(result.value!.system).to be false
      end
    end

    context "with blank name" do
      it "returns Failure with validation errors" do
        result = service.call({ name: "" })
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:validation_error)
      end
    end

    context "with duplicate name" do
      before { create(:tag, name: "дубль") }

      it "returns Failure with errors on name" do
        result = service.call({ name: "дубль" })
        expect(result).to be_failure
        expect(result.failure[:errors]).to have_key(:name)
      end
    end
  end
end
