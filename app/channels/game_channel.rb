class GameChannel < ApplicationCable::Channel
    def subscribed
      stream_for "game_#{game_id}"
    end
  
    def unsubscribed
      stop_all_streams
    end
  end