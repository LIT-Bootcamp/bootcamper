Rails.application.routes.draw do
  devise_for :users, skip: :all

  devise_scope :user do
    get "login", to: "sessions#new", as: :new_user_session
    get "login", to: "sessions#new", as: :login
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout
    get "password/reset", to: "passwords#new", as: :new_password_reset
    post "password/reset", to: "passwords#create", as: :password_reset
    get "password/reset/edit", to: "passwords#edit", as: :edit_password_reset
    patch "password/reset", to: "passwords#update"
  end

  root "home#index"

  get "account", to: "account#show", as: :account
  patch "account", to: "account#update"

  namespace :admin do
    root "overview#show"
  end

  get "register", to: "registrations#new", as: :new_user_registration
  post "register", to: "registrations#create", as: :user_registration
  get "register/success", to: "registrations#success", as: :registration_success
  get "register/confirm", to: "email_confirmations#show", as: :confirmation
  get "register/confirmed", to: "email_confirmations#success", as: :confirmation_success

  namespace :design do
    get "workshop-map", to: "workshop_maps#show", as: :workshop_map
  end
end
