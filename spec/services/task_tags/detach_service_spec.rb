require "rails_helper"

RSpec.describe TaskTags::DetachService do
  subject(:service) { described_class.new }

  let(:task) { create(:task) }
  let(:tag)  { create(:tag) }

  describe "#call" do
    context "when tag is attached" do
      before { task.tags << tag }

      it "detaches the tag and returns Success" do
        result = service.call(task, tag)
        expect(result).to be_success
        expect(task.tags.reload).not_to include(tag)
      end
    end

    context "when tag is not attached" do
      it "returns Failure with not_found code" do
        result = service.call(task, tag)
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:not_found)
      end
    end
  end
end
