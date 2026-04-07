Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  unauthenticated do
    root to: redirect("/users/sign_in"), as: :unauthenticated_root
  end

  get "/dashboard", to: "dashboard#index"
  get "/relatorios/:slug", to: "report_pages#show", as: :report_page

  namespace :admin do
    resources :sidebar_sections
    resources :report_pages
  end
end