Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  end

  devise_for :users

  authenticated :user do
    root "discover#show", as: :authenticated_root
  end
  root "pages#home"

  get "offline", to: "pages#offline"
  get "manifest.webmanifest", to: "pwa#manifest", as: :pwa_manifest
  get "service-worker.js", to: "pwa#service_worker", as: :pwa_service_worker
  get "up", to: "rails/health#show", as: :rails_health_check

  resource :discover, only: :show, controller: "discover"
  resource :map, only: :show
  resource :location, only: %i[update destroy]
  resource :profile, only: %i[show update]
  resources :swipes, only: :create

  resources :dogs do
    resources :comments, only: :create
  end

  resources :users, only: :show

  resources :chatrooms, only: %i[index show create] do
    patch :read, on: :member
    resources :messages, only: :create
  end
end
