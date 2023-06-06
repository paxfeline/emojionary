class GamesController < ApplicationController
  def index
    @game = Game.new
  end

  def show
    #debugger

    @game = Game.find(params[:game_id])
    puts @game.inspect

    #debugger

    if session[:player_id].present?
      @user = Player.find(session[:player_id])

      puts @user.inspect
    else
      @user = Player.new

      if @user.save
        session[:player_id] = @user.id
        cookies[:emoji_game_player_id] = @user.id

        puts @user.inspect
      else
        render :index, status: :unprocessable_entity
      end
    end
  end

  #n = Emoji.all.group_by(&:category).map
  #  { |k,v|
  #    {
  #      category: k,
  #      all: v.map
  #        { |e|
  #          {
  #            raw: e.raw, name: e.name, ios: e.ios_version
  #          }
  #        }
  #    }
  #  };

  def create
    #debugger

    @game = Game.new(game_params)

    # find or create player
    if session[:player_id].present?
      @judge = Player.find(session[:player_id])
    else
      @judge = Player.new
    end
    @game.judge_id = @judge

    if @judge.save && @game.save
      if session[:player_id].nil?
        session[:player_id] = @judge.id
        cookies[:emoji_game_player_id] = @judge.id
      end
      redirect_to "/play?game_id=#{@game.id}"
    else
      render :index, status: :unprocessable_entity
    end
  end

  private
    def game_params
      params.require(:game).permit(:title)
    end
end
