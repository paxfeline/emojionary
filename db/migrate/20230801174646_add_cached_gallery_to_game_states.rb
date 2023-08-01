class AddCachedGalleryToGameStates < ActiveRecord::Migration[7.0]
  def change
    add_column :game_states, :cached_gallery, :string
  end
end
