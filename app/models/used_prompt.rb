class UsedPrompt < ApplicationRecord
  belongs_to :prompt
  belongs_to :game
end
