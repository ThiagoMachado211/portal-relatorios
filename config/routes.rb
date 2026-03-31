Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  authenticate :user do
    get "/dashboard", to: "dashboard#index"
    resources :sidebar_sections, only: [:show]
    resources :report_pages, only: [:index, :show]
  end

  namespace :admin do
    resources :sidebar_sections
    resources :report_pages
  end
end