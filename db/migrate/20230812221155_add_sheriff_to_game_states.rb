class AddSheriffToGameStates < ActiveRecord::Migration[7.0]
  def change
    add_column :game_states, :sheriff, :boolean
  end
end
