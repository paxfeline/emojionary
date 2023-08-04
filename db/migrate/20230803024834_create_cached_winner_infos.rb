class CreateCachedWinnerInfos < ActiveRecord::Migration[7.0]
  def change
    create_table :cached_winner_infos do |t|
      t.belongs_to :game_state, foreign_key: true
      t.references :cached_winner, foreign_key: {to_table: :players}, type: :uuid
      t.references :cached_prompt, foreign_key: {to_table: :prompts}
      t.string :cached_gallery
      t.string :cached_role

      t.timestamps
    end
  end
end
