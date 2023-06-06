class Game < ApplicationRecord
    after_create :game_setup

    has_many :game_states
    has_many :players, through: :game_states

    #has_one :judge_id, :class_name => "Player", :foreign_key => "id"

private
    def game_setup
        puts "game setup"
        self.deck = "\u{1F600}"
        puts self.deck
    end
end
