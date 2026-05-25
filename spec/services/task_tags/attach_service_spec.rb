require "rails_helper"

RSpec.describe TaskTags::AttachService do
  subject(:service) { described_class.new }

  let(:task) { create(:task) }
  let(:tag)  { create(:tag) }

  describe "#call" do
    it "attaches the tag and returns Success" do
      result = service.call(task, tag)
      expect(result).to be_success
      expect(task.tags.reload).to include(tag)
    end

    it "is idempotent — second call also returns Success" do
      service.call(task, tag)
      result = service.call(task, tag)
      expect(result).to be_success
      expect(task.tags.count).to eq(1)
    end
  end
end
