class CreateDjSets < ActiveRecord::Migration[8.1]
  def change
    create_table :dj_sets do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :dj_sets, :name, unique: true
  end
end
