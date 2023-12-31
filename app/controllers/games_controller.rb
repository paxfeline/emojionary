class GamesController < ApplicationController
  def index
    @game = Game.new
  end

  def show
    #debugger

    @game = Game.find(params[:game_id])
    #puts @game.inspect

    #debugger
    
    puts "game: #{params[:game_id]}\negpi: #{cookies.signed[:emoji_game_player_id]}"

    if cookies.signed[:emoji_game_player_id].present?
      @user = Player.find_by(id: cookies.signed[:emoji_game_player_id])
    end

    if @user.nil?
      @user = Player.new
    end
    
    @user.name ||= Bazaar.super_object

    puts "user name #{@user.name}"

    if @user.save
      cookies.permanent.signed[:emoji_game_player_id] = @user.id
      
      #puts @user.inspect
    else
      render :index, status: :unprocessable_entity and return
    end

    #debugger

    #conn = ActionCable.server.connections.first { |c| c.player_id == @user.id }
    
    # subs is a hash where the keys are json identifiers and the values are Channels
    #subs = conn&.subscriptions.instance_variable_get("@subscriptions")
    
    #chan = subs&.first {|k,v| v.class == "GamesChannel"}&.[](1)
    
    #debugger

    #puts chan.getPlayers
    #if (params[:game_id].present? && chan.present?)
    #  ActionCable.server.broadcast(params[:game_id], { players: chan.getPlayers });
    #end
  end

  def create
    #debugger

    @game = Game.new(game_params)

    # find or create player
    if cookies.signed[:emoji_game_player_id].present?
      @judge = Player.find_by(id: cookies.signed[:emoji_game_player_id])
      if @judge.nil?
        cookies.permanent.signed[:emoji_game_player_id] = nil
        @judge = Player.new
      end
    else
      @judge = Player.new
    end

    @judge.name ||= Bazaar.super_object

    puts "judge name #{@judge.name}"
    
    puts "judge at #{Time.now.to_datetime}"
    @judge.last_judged = Time.now.to_datetime

    #debugger

    if @judge.save
      @game.judge = @judge
      if @game.save
        if cookies.signed[:emoji_game_player_id].nil?
          cookies.permanent.signed[:emoji_game_player_id] = @judge.id
        end
        redirect_to "/play?game_id=#{@game.id}"
      else
        puts "game save fail"
        puts @game.errors.full_messages
        render :index, status: :unprocessable_entity
      end
    else
      puts "judge save fail"
      puts @judge.errors.full_messages
      render :index, status: :unprocessable_entity
    end

    game_state = GameState.new
    game_state.game = @game
    game_state.player_id = @judge.id
    game_state.state = @game.deal
    game_state.sheriff = true

    if !game_state.save
      puts "sheriff game_state save fail"
      puts @judge.errors.full_messages
      render :index, status: :unprocessable_entity
    end
  end

  private
    def game_params
      params.require(:game).permit(:title)
    end
end
