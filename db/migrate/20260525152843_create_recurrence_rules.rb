class CreateRecurrenceRules < ActiveRecord::Migration[8.1]
  def change
    create_table :recurrence_rules do |t|
      t.references :task,         null: false, foreign_key: true, index: { unique: true }
      t.string     :rule_type,    null: false
      t.integer    :interval                        # daily: every N days
      t.integer    :day_of_month                   # monthly: 1–31
      t.date       :specific_dates, array: true, default: []  # specific_dates
      t.string     :even_odd                        # even_odd: 'even' | 'odd'

      t.timestamps
    end
  end
end
