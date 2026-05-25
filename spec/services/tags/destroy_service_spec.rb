require "rails_helper"

RSpec.describe Tags::DestroyService do
  subject(:service) { described_class.new }

  describe "#call" do
    context "with a custom tag" do
      let!(:tag) { create(:tag) }

      it "destroys and returns Success" do
        result = service.call(tag)
        expect(result).to be_success
        expect(Tag.find_by(id: tag.id)).to be_nil
      end
    end

    context "with a system tag" do
      let(:tag) { create(:tag, name: "операции", system: true) }

      it "returns Failure with forbidden code" do
        result = service.call(tag)
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:forbidden)
      end

      it "does not destroy the tag" do
        service.call(tag)
        expect(Tag.find_by(id: tag.id)).to be_present
      end
    end
  end
end
