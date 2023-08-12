class GamesChannel < ApplicationCable::Channel
  def subscribed
    #game = Game.find(game_id)
    stream_from game_id
  end

  def get_next_state
    game_state = GameState.find_by(player_id: player_id, game_id: game_id)
    caches = game_state.cached_winner_infos

    #debugger

    if caches.count > 1

      #caches.shift
      #debugger
      caches[0].destroy
      cached_info = caches[1]

      puts "cache destroyed and next returned"

      transmit({ id: player_id, role: cached_info.cached_role, prompt: cached_info.cached_prompt.prompt, cached: true })
      transmit({ cmd: "show-em", all: JSON.parse(cached_info.cached_gallery), cached: true });
      if cached_info.cached_winner
        transmit({ cmd: "pick", player: cached_info.cached_winner.id, cached: true });
      end

    else
      if caches.count > 0 # should always be true?
        caches[0].destroy
        puts "final cache destroyed"
      else
        puts "no chaches to destroy"
      end
      send_current_round_info
    end

  end

  def send_current_round_info(game = nil, game_state = nil)
    if game.nil?
      game = Game.find(game_id)
    end

    if game_state.nil?
      game_state = GameState.find_by(player_id: player_id, game_id: game_id)
    end

    setupMsg = { id: player_id }
    setupMsg[:role] = game.judge_id == player_id ? "judge" : "artist"
    setupMsg[:hand] = JSON.parse(game_state.state)
    setupMsg[:prompt] = game.prompt.prompt
    setupMsg[:name] = game_state.player.name
    setupMsg[:art_pause] = false

    transmit( setupMsg );
  end

  def after_confirmation_sent
    # broadcast initial message here
    puts "transmitting..."
    
    game = Game.find(game_id)
    
    game_state = GameState.find_by(player_id: player_id, game_id: game_id)
    
    if game_state.nil?
      game_state = GameState.new
      game_state.game = game
      game_state.player_id = player_id
      game_state.state = game.deal
    end

    caches = game_state.cached_winner_infos

    #debugger

    transmit({ id: player_id, name: game_state.player.name, sheriff: game_state.sheriff })

    if caches.count > 0

      cached_info = caches[0]

      # no need to re-transmit id
      transmit({ id: player_id, role: cached_info.cached_role })
      transmit({ cmd: "show-em", all: JSON.parse(cached_info.cached_gallery) });
      if cached_info.cached_winner
        transmit({ cmd: "pick", player: cached_info.cached_winner.id, art_pause: true });
      end

    else

      # if judging, send show-em command (before potential new game state added)
      if game.judging
        transmit({role: game.judge_id == player.id ? "judge" : "artist"})
        o = show_em(game)
        transmit({ cmd: "show-em", all: o })
      end

      if game_state.has_changes_to_save? && !game_state.save
        puts game_state.errors.full_messages
      end

      if !game.judging
        send_current_round_info game, game_state

        # curious why this doesn't seem to work:
        #setupMsg[:players] = getPlayers game
    
        # whyyyyyy... is this necessary? 
        Thread.new do
          Rails.application.executor.wrap do
            #debugger
            broadcastPlayers
            puts "--after threaded players broadcast--"
          end
        end

        #debugger
        getPlayers game
        puts "--after unthreaded getPlayers--"
      end

    end
    
    puts "--end transmission--"
  end

  def getPlayers(game = nil)
    # not sure why it's connecting before this is there...
    return nil if game_id.nil?
    game ||= Game.find(game_id)
    players = game.game_states.inject([]) do |acc, gs|
      #if gs.player_id != game.judge_id
        acc.append({player: gs.player_id, ready: gs.ready, name: gs.player.name, judge: gs.player_id == game.judge_id})
      #end
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

  def show_em(game)
    return game.game_states.all.select { |j| j.player_id != game.judge_id }
      .inject([]) do |acc, gs|
        t = JSON.parse(gs.state).select { |el| el["position"].present? }
        acc.append({player: gs.player_id, art: t, name: gs.player.name})
        acc
      end
  end

  def start_countdown
    game = Game.find(game_id)
    
    # this was here... for no reason?
    #game.players.index_by(&:id)
    
    Thread.new do
      Rails.application.executor.wrap do
        ActionCable.server.broadcast(game_id, { cmd: "countdown", time: 10 });
        sleep 7
        3.downto(1) do |i|
          ActionCable.server.broadcast(game_id, { cmd: "countdown", time: i });
          sleep 1
        end
        ActionCable.server.broadcast(game_id, { cmd: "countdown", time: 0 });
        
        game.judging = true
        if !game.save
          puts "show-em game save error"
        end

        o = show_em(game)
        ActionCable.server.broadcast(game_id, { cmd: "show-em", all: o });

        # cache gallery for all but judge
        artists = GameState.where(game: game)
        artists.each do |tist|
          info = CachedWinnerInfo.new
          #info.game_state = tist
          info.cached_gallery = o.to_json
          info.cached_role = game.judge_id == tist.player.id ? "judge" : "artist"
          #debugger
          info.cached_prompt = game.prompt;
          tist.cached_winner_infos << info
          puts "pre info save"
          if !info.save
            puts "cache save error"
            puts info.errors.full_messages
          end
        end
      end
    end
  end

  def pick(data)
    game = Game.find(game_id)
    game.judging = false
    if !game.save
      puts "pick game save error"
    end
    # send pick command w/ pause
    ActionCable.server.broadcast(game_id, { cmd: "pick", player: data["player"], art_pause: true });

    # cache winner for all but judge
    artists = GameState.where(game: game)
    #debugger
    artists.each do |tist|
      info = tist.cached_winner_infos.last
      info.cached_winner = Player.find(data["player"])
      if !info.save
        puts "cache pick save error"
      end
    end

    #Thread.new do
      #Rails.application.executor.wrap do
        #sleep 5

    # judge
    judge = game.players.order(Arel.sql('last_judged IS NOT NULL, last_judged')).first        
    judge.last_judged = Time.now.to_datetime
    game.judge = judge;
    # prompt
    game.prompt = Prompt.all.select { |i| i.game.nil? || i.game == game }.sample
    
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
      
      #ActionCable.server.broadcast(game_id, { broadcast: o });
    else
      puts "new round fail"
      puts judge.errors.full_messages
      puts game.errors.full_messages
    end
      #end
    #end

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
    game.prompt = Prompt.all.select { |i| i.game.nil? || i.game == game }.sample
    if game.save
      ActionCable.server.broadcast(game_id, { prompt: game.prompt.prompt });
    else
      puts "new prompt failure"
    end
  end

  def custom_prompt(data)
    game = Game.find(game_id)
    cust_propmp = Prompt.new
    cust_propmp.prompt = data["prompt"]
    cust_propmp.game = game
    if cust_propmp.save
      game.prompt = cust_propmp
      if game.save
        ActionCable.server.broadcast(game_id, { prompt: game.prompt.prompt });
      else
        puts "custom prompt game save failure"
      end
    else
      puts "custom prompt save failure"
    end
  end

  def set_name(data)
    player = Player.find(player_id)
    player.name = data["name"]
    if player.save
      transmit(name: data["name"])
      broadcastPlayers
    else
      puts "set name failure"
    end
  end

  def exit_game(id = nil)
    if id.nil?
      id = player_id
    end
    game_state = GameState.find_by(player_id: id, game_id: game_id)
    game_state.destroy

    broadcastPlayers

    #debugger
    ActionCable.server.remote_connections.where(player_id: id, game_id: game_id).disconnect
  end

  def kick(data)
    game_state = GameState.find_by(player_id: player_id, game_id: game_id)
    if game_state.sheriff
      exit_game(data["id"])
    end
  end
end
