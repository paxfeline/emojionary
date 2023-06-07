class Game < ApplicationRecord
    after_create :game_setup

    has_many :game_states
    has_many :players, through: :game_states

    def deal
        puts "deal"

        r = []

        20.times do
            c = self.desk.sample
            ind = rand(c.all.size)
            r.append c.all[ind]
            self.desk.delete(c)
        end

        puts r.inspect

        self.save

        r
    end

private
    def game_setup
        puts "game setup"
        self.deck =
            Emoji.all.group_by(&:category).map do |k,v|
                {
                    category: k,
                    all:
                        v.map do |e|
                            {
                                raw: e.raw, name: e.name, ios: e.ios_version
                            }
                        end
                }
            end
        self.save
    end
end
