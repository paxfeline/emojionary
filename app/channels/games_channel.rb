class GamesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "game_#{params[:game_id]}"
  end

  def after_confirmation_sent
    # broadcast initial message here
    transmit({foo: "bar"})
  end  

  def unsubscribed
    stop_all_streams
  end
end
