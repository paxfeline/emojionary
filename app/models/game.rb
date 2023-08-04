class Game < ApplicationRecord
    before_validation :game_setup

    has_many :game_states
    has_many :players, through: :game_states

    has_many :used_prompts
    belongs_to :prompt

    belongs_to :judge, class_name: "Player"

    has_many :prompts, dependent: :destroy

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
            self.deck = deck.to_json
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

        self.deck = deck.to_json

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
                        v.filter_map do |e|
                            #new_filename = e.image_filename
                            new_filename = "emojis/#{e.hex_inspect.upcase}.svg"
                            #'''
                            # try breaking off just the last part of the filename
                            if not File.exists?("public/#{new_filename}")
                                name_parts = new_filename.split(".")
                                seq_parts = name_parts[0].split("-")
                                if seq_parts.last == "FE0F"
                                    seq_parts.pop
                                    name_parts[0] = seq_parts.join("-")
                                    new_filename = name_parts.join(".")
                                end
                            end
                            #'''

                            # return val:
                            if File.exists?("public/#{new_filename}")
                                {
                                    "raw" => e.raw, "name" => e.name, "ios" => e.ios_version, "position" => nil, "path" => new_filename
                                }
                            else
                                puts "Can't find #{e.name} = #{e.image_filename}, tried #{new_filename}"
                                nil
                            end
                        end
                        
                }
            end

        #debugger

        self.deck ||= deck.to_json
        
        #debugger

        # prompt
        self.prompt ||= Prompt.all.select { |i| i.game.nil? }.sample

        self.judging ||= false

        puts "game setup done"
        puts self.inspect
        
        #up = UsedPrompt.new
        #up.prompt = self.prompt
        #up.game = self
        #up.save

        #puts self.inspect
        #self.save
    end
end
