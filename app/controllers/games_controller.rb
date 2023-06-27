class GamesController < ApplicationController
  def index
    @game = Game.new
  end

  def show
    #debugger

    @game = Game.find(params[:game_id])
    #puts @game.inspect

    #debugger

    if cookies[:emoji_game_player_id].present?
      @user = Player.find_by(id: cookies[:emoji_game_player_id])
    end

    if @user.nil?
      @user = Player.new

      if @user.save
        cookies[:emoji_game_player_id] = @user.id

        #puts @user.inspect
      else
        render :index, status: :unprocessable_entity
      end
    end
  end

  def create
    #debugger

    @game = Game.new(game_params)

    # find or create player
    if cookies[:emoji_game_player_id].present?
      @judge = Player.find_by(id: cookies[:emoji_game_player_id])
      if @judge.nil?
        cookies[:emoji_game_player_id] = nil
        @judge = Player.new
      end
    else
      @judge = Player.new
    end
    
    puts "judge at #{Time.now.to_datetime}"
    @judge.last_judged = Time.now.to_datetime

    #debugger

    if @judge.save
      @game.judge = @judge
      if @game.save
        if cookies[:emoji_game_player_id].nil?
          cookies[:emoji_game_player_id] = @judge.id
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
  end

  private
    def game_params
      params.require(:game).permit(:title)
    end
end
