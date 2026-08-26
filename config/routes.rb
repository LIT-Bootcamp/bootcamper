Rails.application.routes.draw do
  root "home#index"

  namespace :design do
    get "workshop-map", to: "workshop_maps#show", as: :workshop_map
  end
end
