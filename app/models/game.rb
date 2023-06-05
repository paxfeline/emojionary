class Game < ApplicationRecord
    after_create :game_setup

    has_many :game_states
    has_many :players, through: :game_states

    has_one :judge, :class_name => "Player", :foreign_key => "id"

private
    def game_setup
        puts "game setup"
        self.deck = "\u1F600".encode('utf-8')
        puts self.deck
    end
end
