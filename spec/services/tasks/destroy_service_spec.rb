require "rails_helper"

RSpec.describe Tasks::DestroyService do
  subject(:service) { described_class.new }

  let!(:task) { create(:task) }

  describe "#call" do
    it "returns Success and deletes the task" do
      result = service.call(task)
      expect(result).to be_success
      expect(Task.find_by(id: task.id)).to be_nil
    end

    it "decrements task count" do
      expect { service.call(task) }.to change(Task, :count).by(-1)
    end
  end
end
