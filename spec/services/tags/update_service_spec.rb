require "rails_helper"

RSpec.describe Tags::UpdateService do
  subject(:service) { described_class.new }

  describe "#call" do
    context "with a custom tag and valid params" do
      let(:tag) { create(:tag, name: "старое") }

      it "updates and returns Success" do
        result = service.call(tag, { name: "новое" })
        expect(result).to be_success
        expect(result.value!.name).to eq("новое")
      end
    end

    context "with a system tag" do
      let(:tag) { create(:tag, name: "отчетность", system: true) }

      it "returns Failure with forbidden code" do
        result = service.call(tag, { name: "новое" })
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:forbidden)
      end
    end

    context "with blank name" do
      let(:tag) { create(:tag) }

      it "returns Failure" do
        result = service.call(tag, { name: "" })
        expect(result).to be_failure
      end
    end
  end
end
