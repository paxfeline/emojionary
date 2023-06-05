class GamesController < ApplicationController
  def index
    @game = Game.new
  end

  def show
    @game = Game.find(params[:game_id])
    puts @game.inspect

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
    @game = Game.new(game_params)
    @judge = Player.new
    @game.judge = @judge
    #@game.

    if @game.save && @judge.save
      session[:player_id] = @judge.id
      cookies[:emoji_game_player_id] = @judge.id
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
