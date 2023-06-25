module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :player_id #, :game_id

    def connect
      puts "cookies"
      puts cookies.inspect
      self.player_id = cookies[:emoji_game_player_id]
      #debugger
      #self.game_id = request.params[:game_id]
    end
  end
end
