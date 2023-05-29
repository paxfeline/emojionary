Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "games#index"

  get "/games", to: "games#index"
  get "/play", to: "games#show"
  post "/games", to: "games#create"
end
