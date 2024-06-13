class RemoveCommentsFromTracks < ActiveRecord::Migration[7.1]
  def change
    remove_column :tracks, :comments, :string
  end
end
