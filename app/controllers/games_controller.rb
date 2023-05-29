class GamesController < ApplicationController
  def index
    @game = Game.new
  end

  def show
    @game = Game.find(params[:game_id])
  end

  def create
    @game = Game.new(game_params)

    if @game.save
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
