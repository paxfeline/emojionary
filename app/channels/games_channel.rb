class GamesChannel < ApplicationCable::Channel
  def subscribed
    #game = Game.find(game_id)
    stream_from game_id
  end

  def after_confirmation_sent
    # broadcast initial message here
    puts "transmitting..."
    
    #transmit( { cmd: "id", id: player_id } )
    setupMsg = { id: player_id };
    
    game = Game.find(game_id)
    player = Player.find(player_id)
    
    if game.judge_id == player.id
      #transmit( { cmd: "judge" } )
      setupMsg[:role] = "judge"
    else
      #transmit( { cmd: "artist" } )
      setupMsg[:role] = "artist"
    end
    
    #debugger
    
    game_state = GameState.find_by(player_id: player_id, game_id: game_id)
    
    if game_state.nil?
      game_state = GameState.new
      game_state.game = game
      game_state.player = player
      hand = game.deal
      game_state.state = hand
    else
      hand = game_state.state
    end
    
    #puts hand.inspect
    
    if !game_state.save
      puts game_state.errors.full_messages
    end
    
    #transmit( { cmd: "hand", hand: hand } )
    setupMsg[:hand] = JSON.parse(hand);
    
    #transmit( { cmd: "prompt", prompt: game.prompt.prompt })
    setupMsg[:prompt] = game.prompt.prompt
    
    setupMsg[:judging] = game.judging

    #setupMsg[:players] = getPlayers game

    transmit( setupMsg );

    # whyyyyyy... is this necessary? 
    Thread.new do
      Rails.application.executor.wrap do
        #debugger
        broadcastPlayers
        puts "--players broadcast--"
      end
    end
    
    puts "--end transmission--"
  end

  def getPlayers(game = nil)
    # not sure why it's connecting before this is there...
    return nil if game_id.nil?
    game ||= Game.find(game_id)
    players = game.game_states.inject([]) do |acc, gs|
      if gs.player_id != game.judge_id
        acc.append({player: gs.player_id, ready: gs.ready, name: gs.player.name})
      end
      acc
    end
    #debugger
    players
  end

  def broadcastPlayers
    ActionCable.server.broadcast(game_id, { players: getPlayers });
  end

  def unsubscribed
    stop_all_streams
  end

  def start_countdown
    game = Game.find(game_id)
    game.players.index_by(&:id) 
    Thread.new do
      Rails.application.executor.wrap do
        # your code here
        15.step(5, -5) do |i|
          ActionCable.server.broadcast(game_id, { cmd: "countdown", time: i });
          sleep 5
        end
        ActionCable.server.broadcast(game_id, { cmd: "countdown", time: 0 });
        o = game.game_states.all.select { |j| j.player_id != game.judge_id }
          .inject([]) do |acc, gs|
            t = JSON.parse(gs.state).select { |el| el["position"].present? }
            acc.append({player: gs.player_id, art: t, name: gs.player.name})
            acc
          end
        ActionCable.server.broadcast(game_id, { cmd: "show-em", all: o });
      end
    end
  end

  def pick(data)
    game = Game.find(game_id)
    ActionCable.server.broadcast(game_id, { cmd: "pick", player: data["player"] });

    Thread.new do
      Rails.application.executor.wrap do
        sleep 5

        judge = game.players.order(Arel.sql('last_judged IS NOT NULL, last_judged')).first        
        judge.last_judged = Time.now.to_datetime
        game.prompt = Prompt.all.sample
        game.judge = judge;

        # prompt
        game.prompt = Prompt.all.sample
        
        if judge.save && game.save
          o = game.players.inject([]) do |acc, pl|
            game_state = GameState.find_by(player_id: pl.id, game_id: game.id)
            start_hand = JSON.parse(game_state.state)
            nec = start_hand.select { |el| el["position"].present? }.count
            hand = start_hand.select { |el| el["position"].nil? }
            nec.times { hand.append(game.deal_one) }
            game_state.state = hand.to_json
            game_state.ready = false
            if game_state.save
              acc.append(
                {
                  player: pl.id,
                  data:
                    {
                      prompt: game.prompt.prompt,
                      role: pl.id == judge.id ? "judge" : "artist",
                      hand: hand
                    }
                }
              )
            else
              puts "hand update save error"
            end
          end
          
          ActionCable.server.broadcast(game_id, { broadcast: o });
        else
          puts "new round fail"
          puts judge.errors.full_messages
          puts game.errors.full_messages
        end
      end
    end

  end

  def update(data)
    puts "update CALLED"
    #puts data

    #player = Player.find(player_id)
    #game = Game.find(game_id)
    
    #debugger

    game_state = GameState.find_by(player_id: player_id, game_id: game_id)
    game_state.state = data["hand"].to_json
    game_state.save
  end

  def trade_in(data)
    game = Game.find(game_id)
    game_state = GameState.find_by(player_id: player_id, game_id: game_id)
    start_hand = JSON.parse(game_state.state)
    hand = start_hand.reject { |el| el["name"] == data["emoji"] }
    hand.append(game.deal_one)
    game_state.state = hand.to_json
    if game_state.save
      transmit( {hand: hand} );
    else
      puts "game_state trade-in save failure"
    end
  end

  def set_ready
    game_state = GameState.find_by(player_id: player_id, game_id: game_id)
    game_state.ready = true
    if game_state.save
      broadcastPlayers
    else
      puts "set ready gs save error"
    end
  end

  def new_prompt
    game = Game.find(game_id)
    game.prompt = Prompt.all.sample
    if game.save
      ActionCable.server.broadcast(game_id, { prompt: game.prompt.prompt });
    else
      puts "new prompt failure"
    end
  end

  def set_name(data)
    player = Player.find(player_id)
    player.name = data["name"]
    if player.save
      broadcastPlayers
    else
      puts "set name failure"
    end
  end

  def exit_game
    game_state = GameState.find_by(player_id: player_id, game_id: game_id)
    game_state.destroy

    broadcastPlayers

    #debugger
    ActionCable.server.remote_connections.where(player_id: player_id, game_id: game_id).disconnect
  end
end
