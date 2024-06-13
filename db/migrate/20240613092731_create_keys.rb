class CreateKeys < ActiveRecord::Migration[7.1]
  def change
    create_table :keys do |t|
      t.string :name

      t.timestamps
    end
    add_index :keys, :name, unique: true
    add_column :tracks, :key_id, :integer
    add_index :tracks, :key_id
  end
end
