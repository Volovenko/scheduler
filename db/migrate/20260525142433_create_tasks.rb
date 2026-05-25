class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.date :due_date
      t.string :status, null: false, default: "pending"
      t.boolean :recurring, null: false, default: false
      t.date :starts_on
      t.date :ends_on

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :due_date
  end
end
