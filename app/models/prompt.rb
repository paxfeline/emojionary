class Prompt < ApplicationRecord
    belongs_to :game, optional: true
end
