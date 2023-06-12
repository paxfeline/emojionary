class AddGamesTable < ActiveRecord::Migration[7.0]
  def change
    create_table :players, id: :uuid do |t|
      t.string :name
      t.datetime :last_judged

      t.timestamps
    end
    create_table :games, id: :uuid do |t|
      t.string :title
      t.references :judge, null: false, index: true, foreign_key: {to_table: :players}, type: :uuid
      t.string :deck

      t.timestamps
    end
  end
end
