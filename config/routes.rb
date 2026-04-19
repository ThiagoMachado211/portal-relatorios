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
  get "/relatorios/:section_slug/:subsection_slug", to: "report_pages#subsection", as: :report_subsection

  namespace :admin do
    resources :users
    resources :sidebar_sections
    resources :sidebar_subsections do
      collection do
        get :by_section
      end
    end
    resources :report_pages
  end

  resources :travel_metrics do
    collection do
      get :dashboard
      get :presentation
    end
  end

  resources :long_trips, only: [:index, :new, :create] do
    collection do
      get :dashboard
      get :presentation
      get :import
      post :import_file
    end
  end

end