Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root "dashboard#index", as: :authenticated_root

    get "/dashboard", to: "dashboard#index"

    resources :sidebar_sections, only: [:show]
    resources :report_pages, only: [:index, :show]
  end

  unauthenticated do
    root to: redirect("/users/sign_in"), as: :unauthenticated_root
  end

  namespace :admin do
    resources :sidebar_sections
    resources :report_pages
  end
end