class CreateUsedPrompts < ActiveRecord::Migration[7.0]
  def change
    create_table :used_prompts do |t|
      t.references :prompt, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
