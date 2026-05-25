class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string  :name,   null: false
      t.boolean :system, null: false, default: false

      t.timestamps
    end

    add_index :tags, :name, unique: true
  end
end
