class GamesChannel < ApplicationCable::Channel
  def subscribed
    #game = Game.find(params[:game_id])
    stream_from params[:game_id]
  end

  def after_confirmation_sent
    # broadcast initial message here
    puts "transmitting..."
    
    #transmit( { cmd: "id", id: player_id } )
    setupMsg = { id: player_id };
    
    game = Game.find(params[:game_id])
    player = Player.find(player_id)
    
    if game.judge_id == player.id
      #transmit( { cmd: "judge" } )
      setupMsg[:role] = "judge"
    else
      #transmit( { cmd: "artist" } )
      setupMsg[:role] = "artist"
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
    
    #puts hand.inspect
    
    game_state.save
    
    #transmit( { cmd: "hand", hand: hand } )
    setupMsg[:hand] = JSON.parse(hand);
    
    #transmit( { cmd: "prompt", prompt: game.prompt.prompt })
    setupMsg[:prompt] = game.prompt.prompt
    
    setupMsg[:judging] = game.judging

    #debugger

    setupMsg[:players] = getPlayers game

    transmit( setupMsg );

    puts "--end transmission--"
  end

  def getPlayers(game)
    game ||= Game.find(params[:game_id])
    players = game.game_states.inject([]) do |acc, gs|
      acc.append({player: gs.player.id, ready: gs.ready})
      acc
    end
    players
  end

  def broadcastPlayers
    ActionCable.server.broadcast(params[:game_id], { players: getPlayers });
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
        15.step(5, -5) do |i|
          ActionCable.server.broadcast(params[:game_id], { cmd: "countdown", time: i });
          sleep 5
        end
        ActionCable.server.broadcast(params[:game_id], { cmd: "countdown", time: 0 });
        o = game.game_states.all.select { |j| j.player_id != game.judge_id }
          .inject([]) do |acc, gs|
            t = JSON.parse(gs.state).select { |el| el["position"].present? }
            acc.append({player: gs.player_id, art: t})
            acc
          end
        ActionCable.server.broadcast(params[:game_id], { cmd: "show-em", all: o });
      end
    end
  end

  def pick(data)
    game = Game.find(params[:game_id])
    ActionCable.server.broadcast(params[:game_id], { cmd: "pick", player: data["player"] });

    Thread.new do
      Rails.application.executor.wrap do
        sleep 5

        judge = game.players.order(Arel.sql('last_judged IS NOT NULL, last_judged')).first        
        judge.last_judged = Time.now.to_datetime
        game.prompt = Prompt.all.sample
        game.judge = judge;
        
        # use usedprompt
        up = UsedPrompt.new
        up.prompt = game.prompt
        up.game = game
        up.save

        # prompt
        game.prompt = Prompt.all.sample
        
        if judge.save && game.save
          o = game.players.inject([]) do |acc, pl|
            game_state = GameState.find_by({player_id: pl.id, game_id: game.id})
            start_hand = JSON.parse(game_state.state)
            nec = start_hand.select { |el| el["position"].present? }.count
            hand = start_hand.select { |el| el["position"].nil? }
            nec.times { hand.append(game.deal_one) }
            game_state.state = hand.to_json
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
          
          ActionCable.server.broadcast(params[:game_id], { broadcast: o });
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

    game_state = GameState.find_by({player_id: player_id, game_id: params[:game_id]})
    game_state.state = data["hand"].to_json
    game_state.save
  end

  def trade_in(data)
    game = Game.find(params[:game_id])
    game_state = GameState.find_by({player_id: player_id, game_id: game.id})
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
end
