class CreateGameStates < ActiveRecord::Migration[7.0]
  def change
    create_table :game_states do |t|
      t.references :player, null: false, foreign_key: true, type: :uuid
      t.references :game, null: false, foreign_key: true, type: :uuid
      t.string :state
      t.boolean :ready

      t.timestamps
    end
  end
end
