class Player < ApplicationRecord
    has_many :game_states
    has_many :games, through: :game_states
end
