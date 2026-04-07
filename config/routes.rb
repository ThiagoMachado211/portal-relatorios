Rails.application.routes.draw do
  devise_for :users

  root to: redirect("/users/sign_in")

  get "/dashboard", to: "dashboard#index"
end