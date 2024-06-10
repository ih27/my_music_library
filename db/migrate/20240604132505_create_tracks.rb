class CreateTracks < ActiveRecord::Migration[7.1]
  def change
    create_table :tracks do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.decimal :bpm, null: false, precision: 5, scale: 2
      t.integer :time
      t.string :album
      t.string :comments
      t.date :date_added, null: false

      t.timestamps
    end
  end
end
