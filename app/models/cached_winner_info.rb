class CachedWinnerInfo < ApplicationRecord
    belongs_to :game_state, inverse_of: :cached_winner_infos
    belongs_to :cached_winner, class_name: "Player", optional: true
    belongs_to :cached_prompt, class_name: "Prompt"
end
