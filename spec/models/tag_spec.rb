# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  system     :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tags_on_name  (name) UNIQUE
#
require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "validations" do
    subject { build(:tag) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
  end

  describe "associations" do
    it { is_expected.to have_many(:task_tags).dependent(:destroy) }
    it { is_expected.to have_many(:tasks).through(:task_tags) }
  end

  describe "scopes" do
    let!(:system_tag) { create(:tag, :system, name: "отчетность") }
    let!(:custom_tag) { create(:tag) }

    describe ".system_tags" do
      it { expect(described_class.system_tags).to include(system_tag) }
      it { expect(described_class.system_tags).not_to include(custom_tag) }
    end

    describe ".custom_tags" do
      it { expect(described_class.custom_tags).to include(custom_tag) }
      it { expect(described_class.custom_tags).not_to include(system_tag) }
    end
  end
end
