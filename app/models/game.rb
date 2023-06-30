class Game < ApplicationRecord
    before_validation :game_setup

    has_many :game_states
    has_many :players, through: :game_states

    has_many :used_prompts
    belongs_to :prompt

    belongs_to :judge, class_name: "Player"

    def deal_one(deck = nil)
        if deck.nil?
            deck = JSON.parse self.deck
        end

        cat = deck.sample
        ind = rand(cat["all"].size)
        #puts cat["all"][ind]
        r = cat["all"][ind]
        cat["all"].delete_at(ind)

        if deck.nil?
            self.deck = deck
            self.save
        end

        return r
    end

    def deal
        puts "deal"

        hand = []

        #debugger

        deck = JSON.parse self.deck

        20.times do
            em = deal_one deck
            hand.append em
        end

        self.deck = deck

        self.save

        #debugger

        return hand.to_json
    end

private
    def game_setup
        puts "game setup"

        # emojis

        # Emoji.all.group_by(&:category).map { |k,v| { category: k, all: v.map { |e| { raw: e.raw, name: e.name, ios: e.ios_version } } } }
        deck ||=
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

        self.deck ||= deck.to_json

        # prompt
        self.prompt ||= Prompt.all.sample

        self.judging ||= false
        
        #up = UsedPrompt.new
        #up.prompt = self.prompt
        #up.game = self
        #up.save

        #puts self.inspect
        #self.save
    end
end
