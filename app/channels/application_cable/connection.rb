module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :player_id, :game_id

    def connect
      #puts "cookies"
      #puts cookies.inspect
      self.player_id = cookies[:emoji_game_player_id]
      #debugger
      self.game_id = request.params[:game_id]
      #debugger
      #self.game_id = request.params[:game_id]
    end

    #def disconnect
      # don't destroy game state right away...
      # after a delay in case they reconnect?

      #debugger

      #game_state = GameState.find_by(player_id: self.player_id, game_id: self.game_id)
      #game_state&.destroy
  
      #broadcastPlayers
    #end

    # fucking dup code
    def getPlayers
      game = Game.find(self.game_id)
      players = game.game_states.inject([]) do |acc, gs|
        if gs.player_id != game.judge_id
          acc.append({player: gs.player_id, ready: gs.ready})
        end
        acc
      end
      #debugger
      players
    end

    def broadcastPlayers
      ActionCable.server.broadcast(request.params[:game_id], { players: getPlayers });
    end
  end
end
