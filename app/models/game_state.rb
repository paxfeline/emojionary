class GameState < ApplicationRecord
  before_validation :game_state_setup

  belongs_to :player
  belongs_to :game

  has_many :cached_winner_infos, inverse_of: :game_state

  private
  def game_state_setup
    self.ready ||= false
  end
end
