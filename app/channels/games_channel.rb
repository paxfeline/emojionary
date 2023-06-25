class GamesChannel < ApplicationCable::Channel
  def subscribed
    #game = Game.find(params[:game_id])
    stream_from params[:game_id]
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

  def start_countdown
    game = Game.find(params[:game_id])
    game.players.index_by(&:id) 
    Thread.new do
      Rails.application.executor.wrap do
        # your code here
        30.step(1, -5) do |i|
          ActionCable.server.broadcast(params[:game_id], { cmd: "countdown", time: i });
          sleep 5
        end
        ActionCable.server.broadcast(params[:game_id], { cmd: "countdown", time: 0 });
        o = game.game_states.all.inject([]) do |acc, gs|
          t = JSON.parse(gs.state).select { |el| el["position"].present? }
          acc.append({player: gs.player_id, art: t})
          acc
        end
        ActionCable.server.broadcast(params[:game_id], { cmd: "show-em", all: o });
      end
    end
  end

  def judge_select_choice

  end

  def update(data)
    puts "update CALLED"
    puts data

    #player = Player.find(player_id)
    #game = Game.find(game_id)
    
    #debugger

    game_state = GameState.find_by({player_id: player_id, game_id: params[:game_id]})
    game_state.state = data["hand"].to_json
    game_state.save
  end
end
