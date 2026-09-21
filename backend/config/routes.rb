Rails.application.routes.draw do
  mount OpenapiRuby::Engine => "/api-docs"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "me" => "me#show"
      patch "me/password" => "me#update_password"
      post "me/otp/setup" => "me#otp_setup"
      post "me/otp/enable" => "me#otp_enable"
      post "me/otp/disable" => "me#otp_disable"
      post "signup" => "signups#create"
      post "login" => "sessions#create"
      post "login/otp" => "sessions#verify_otp"
      delete "logout" => "sessions#destroy"
      post "discounts/validate" => "discount_validations#create"
      post "discounts/redeem" => "discount_redemptions#create"
      post "customers" => "customers#create"
      get "customers/:id" => "customers#show"

      namespace :admin do
        resource :account, only: %i[show update], controller: "account"
        resources :users, only: %i[index show create update destroy] do
          member do
            patch :reset_password
            post :reset_otp
          end
        end
        resources :projects, only: %i[index show create update destroy]
        resources :project_memberships, only: %i[index show create update destroy]
        resources :api_keys, only: %i[index show create destroy]
        resources :campaigns, only: %i[index show create update] do
          collection { get :export }
        end
        resources :discounts, only: %i[index show create update destroy] do
          get :design_image, on: :member
          post :design_image, action: :upload_design_image, on: :member
          resources :compatible_discounts, only: %i[create destroy], controller: "discount_compatibilities"
          resources :coupon_codes, only: %i[index create destroy]
        end
        resources :custom_attributes, only: %i[index create destroy]
        resources :orders, only: %i[index show] do
          post :cancel, on: :member
          collection { get :export }
        end
        resources :order_discounts, only: [] do
          post :refund, on: :member
        end
        resources :points_redemptions, only: [] do
          post :refund, on: :member
        end
        resources :customers, only: %i[index show update] do
          post :grant_points, on: :member
          collection { get :export }
        end
        get "exports/project" => "exports#project"
        get "analytics/coupons" => "analytics#coupons"
        get "analytics/promotions" => "analytics#promotions"
        get "analytics/loyalty" => "analytics#loyalty"
        get "analytics/loyalty/active_redemptions" => "analytics#loyalty_active_redemptions"
        get "analytics/customers" => "analytics#customers"
        get "analytics/campaigns" => "analytics#campaigns"
        get "analytics/orders" => "analytics#orders"
        resources :membership_schemes, only: %i[index show create update] do
          resources :tiers, only: %i[create update], controller: "membership_tiers"
          collection { post :evaluate }
        end
        resources :gift_shop_items, only: %i[index show create update destroy] do
          get :photo, on: :member
          post :photo, action: :upload_photo, on: :member
          post :redeem, on: :member
        end
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
