class GamesChannel < ApplicationCable::Channel
  def subscribed
    game = Game.find(params[:game_id])
    stream_for game
  end

  def after_confirmation_sent
    # broadcast initial message here
    puts "transmitting..."
    
    transmit( { cmd: "id", id: player_id } )
    
    game = Game.find(params[:game_id])
    player = Player.find(player_id)
    
    if game.judge_id == player.id
      transmit( { cmd: "judge" } )
    else
      transmit( { cmd: "artist" } )
    end

    #debugger

    #game_state = GameState.find_by(player_id: player_id)
    game_state = GameState.find_by({player_id: player_id, game_id: game.id})

    if game_state.nil?
      game_state = GameState.new
      game_state.game = game
      game_state.player = player
      hand = game.deal
      game_state.state = hand
    else
      hand = game_state.state
    end

    puts hand.inspect

    game_state.save

    transmit( { cmd: "hand", hand: hand } )

    puts "--end transmission--"
  end  

  def unsubscribed
    stop_all_streams
  end

  def judge_select_choice

  end
end
