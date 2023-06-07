class Game < ApplicationRecord
    after_create :game_setup

    has_many :game_states
    has_many :players, through: :game_states

    def deal
        puts "deal"

        hand = []

        #debugger

        deck = JSON.parse self.deck


        20.times do
            cat = deck.sample
            ind = rand(cat["all"].size)
            #puts cat["all"][ind]
            hand.append cat["all"][ind]
            cat["all"].delete(ind)
        end

        self.save

        return hand
    end

private
    def game_setup
        puts "game setup"
        # Emoji.all.group_by(&:category).map { |k,v| { category: k, all: v.map { |e| { raw: e.raw, name: e.name, ios: e.ios_version } } } }
        deck =
            Emoji.all.group_by(&:category).map do |k,v|
                {
                    category: k,
                    all:
                        v.filter {|u| u.ios_version.split(".")[0].to_i < 15}.map do |e|
                            {
                                "raw" => e.raw, "name" => e.name, "ios" => e.ios_version
                            }
                        end
                }
            end
        #debugger
        self.deck = JSON.generate deck
        puts self.inspect
        self.save
    end
end
