class GamesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "game_#{params[:game_id]}"
  end

  def after_confirmation_sent
    # broadcast initial message here
    puts "transmitting..."
    #debugger

    transmit( {foo: "bar"} )
    transmit( { id: player_id } )

    puts "end"
  end  

  def unsubscribed
    stop_all_streams
  end
end
