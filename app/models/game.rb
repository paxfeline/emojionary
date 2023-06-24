class Game < ApplicationRecord
    after_create :game_setup

    has_many :game_states
    has_many :players, through: :game_states

    has_many :used_prompts
    has_many :prompts, through: :used_prompts

    belongs_to :prompt
    belongs_to :judge, class_name: "Player"

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

        #debugger

        return hand.to_json
    end

private
    def game_setup
        puts "game setup"

        # emojis

        # Emoji.all.group_by(&:category).map { |k,v| { category: k, all: v.map { |e| { raw: e.raw, name: e.name, ios: e.ios_version } } } }
        deck =
            Emoji.all.group_by(&:category).map do |k,v|
                {
                    category: k,
                    all:
                        # filtering out ios >= 15 'cause I can't see 'em on this laptop
                        v.filter {|u| u.ios_version.split(".")[0].to_i < 15}.map do |e|
                            {
                                "raw" => e.raw, "name" => e.name, "ios" => e.ios_version, "position" => nil
                            }
                        end
                }
            end
        #debugger
        self.deck = deck.to_json

        # prompt
        
        up = UsedPrompt.new
        up.prompt = self.prompt
        up.game = self

        puts self.inspect
        self.save
    end
end
