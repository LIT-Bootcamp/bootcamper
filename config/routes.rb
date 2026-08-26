Rails.application.routes.draw do
  root "home#index"

  get "register", to: "registrations#new", as: :new_user_registration
  post "register", to: "registrations#create", as: :user_registration
  get "register/success", to: "registrations#success", as: :registration_success

  namespace :design do
    get "workshop-map", to: "workshop_maps#show", as: :workshop_map
  end
end
