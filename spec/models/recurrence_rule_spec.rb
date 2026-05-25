# == Schema Information
#
# Table name: recurrence_rules
#
#  id             :bigint           not null, primary key
#  day_of_month   :integer
#  even_odd       :string
#  interval       :integer
#  rule_type      :string           not null
#  specific_dates :date             default([]), is an Array
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  task_id        :bigint           not null
#
# Indexes
#
#  index_recurrence_rules_on_task_id  (task_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (task_id => tasks.id)
#
require "rails_helper"

RSpec.describe RecurrenceRule, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:task) }
  end

  describe "validations" do
    context "rule_type inclusion" do
      it "is valid for each supported rule type" do
        RecurrenceRule::RULE_TYPES.each do |type|
          attrs = base_attrs_for(type)
          rule  = build(:recurrence_rule, **attrs)
          expect(rule).to be_valid, "expected '#{type}' to be valid"
        end
      end

      it "is invalid for an unknown rule_type" do
        rule = build(:recurrence_rule, rule_type: "weekly")
        expect(rule).not_to be_valid
        expect(rule.errors[:rule_type]).to be_present
      end
    end

    context "daily rule" do
      it "requires interval" do
        rule = build(:recurrence_rule, :daily, interval: nil)
        expect(rule).not_to be_valid
        expect(rule.errors[:interval]).to be_present
      end

      it "requires interval > 0" do
        rule = build(:recurrence_rule, :daily, interval: 0)
        expect(rule).not_to be_valid
      end

      it "is valid with interval = 1" do
        rule = build(:recurrence_rule, :daily, interval: 1)
        expect(rule).to be_valid
      end
    end

    context "monthly rule" do
      it "requires day_of_month" do
        rule = build(:recurrence_rule, :monthly, day_of_month: nil)
        expect(rule).not_to be_valid
        expect(rule.errors[:day_of_month]).to be_present
      end

      it "rejects day_of_month = 0" do
        rule = build(:recurrence_rule, :monthly, day_of_month: 0)
        expect(rule).not_to be_valid
      end

      it "rejects day_of_month > 31" do
        rule = build(:recurrence_rule, :monthly, day_of_month: 32)
        expect(rule).not_to be_valid
      end

      it "is valid with day_of_month = 15" do
        rule = build(:recurrence_rule, :monthly, day_of_month: 15)
        expect(rule).to be_valid
      end
    end

    context "specific_dates rule" do
      it "requires specific_dates to be present" do
        rule = build(:recurrence_rule, :specific_dates, specific_dates: [])
        expect(rule).not_to be_valid
        expect(rule.errors[:specific_dates]).to be_present
      end

      it "is valid with at least one date" do
        rule = build(:recurrence_rule, :specific_dates)
        expect(rule).to be_valid
      end
    end

    context "even_odd rule" do
      it "requires even_odd value" do
        rule = build(:recurrence_rule, :even_days, even_odd: nil)
        expect(rule).not_to be_valid
        expect(rule.errors[:even_odd]).to be_present
      end

      it "rejects invalid even_odd value" do
        rule = build(:recurrence_rule, :even_days, even_odd: "weekly")
        expect(rule).not_to be_valid
      end

      it "is valid with 'even'" do
        rule = build(:recurrence_rule, :even_days)
        expect(rule).to be_valid
      end

      it "is valid with 'odd'" do
        rule = build(:recurrence_rule, :odd_days)
        expect(rule).to be_valid
      end
    end
  end

  private

  def base_attrs_for(type)
    case type
    when "daily"          then { rule_type: "daily",          interval: 1 }
    when "monthly"        then { rule_type: "monthly",        day_of_month: 1, interval: nil }
    when "specific_dates" then { rule_type: "specific_dates", specific_dates: [Date.current], interval: nil }
    when "even_odd"       then { rule_type: "even_odd",       even_odd: "even", interval: nil }
    end
  end
end
