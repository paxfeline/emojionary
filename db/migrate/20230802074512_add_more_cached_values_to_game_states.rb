class AddMoreCachedValuesToGameStates < ActiveRecord::Migration[7.0]
  def change
    add_column :game_states, :cached_role, :string
    add_reference :game_states, :cached_prompt, foreign_key: {to_table: :prompts}
  end
end
