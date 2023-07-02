class GameState < ApplicationRecord
  before_validation :game_state_setup

  belongs_to :player
  belongs_to :game

  private
  def game_state_setup
    self.ready ||= false
  end
end
