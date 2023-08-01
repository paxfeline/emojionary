class AddCachedWinnerToGameStates < ActiveRecord::Migration[7.0]
  def change
    add_column :game_states, :cached_winner, :string
  end
end
