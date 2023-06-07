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

    @game = Game.find(params[:game_id])

    hand = @game.deal

    puts hand.inspect

    transmit( { hand: hand } )

    puts "--end transmission--"
  end  

  def unsubscribed
    stop_all_streams
  end
end
