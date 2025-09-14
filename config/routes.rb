Rails.application.routes.draw do
  # Authentication routes
  get 'signup', to: 'users#new', as: 'signup'
  post 'signup', to: 'users#create'
  get 'login', to: 'sessions#new', as: 'login'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: 'logout'
  
  # User routes
  resources :users, only: [:show, :edit, :update]
  
  # Admin routes
  namespace :admin do
    get '/', to: 'dashboard#index', as: :dashboard
    resources :users do
      member do
        post :reset_trial
      end
    end
    resources :orders
                  resources :products do
      member do
        patch :toggle_status
      end
      collection do
        post :update_trial_prices
        post :bulk_toggle_status
      end
    end
    
    patch 'validity_options/:validity_option_id/toggle', to: 'products#toggle_validity_option', as: :toggle_validity_option
                  resources :contacts, only: [:index, :show, :update, :destroy] do
                collection do
                  post :bulk_update
                end
              end
  end
  
  # Main pages
  root "home#index"
  get 'home/index'
  get 'products', to: 'home#products'
  get 'products/:id', to: 'home#product_detail', as: 'product_detail'
  get 'products/:id/validity_options', to: 'home#validity_options'
  # get 'pricing', to: 'home#pricing'
  get 'contact', to: 'home#contact'
  get 'about', to: 'home#about'
  get 'features', to: 'home#features'
  
  # Legal pages
  get 'privacy-policy', to: 'legal#privacy_policy'
  get 'terms-and-conditions', to: 'legal#terms_and_conditions'
  get 'return-refund-policy', to: 'legal#return_refund_policy'
  
  # Cart routes
  resource :cart, only: [:show] do
    collection do
      post :add_item
      delete :remove_item
      patch :update_quantity
      delete :clear
    end
  end
  
  # Checkout routes with offers
  get 'checkout', to: 'checkout#index'
  post 'checkout/apply_offer', to: 'checkout#apply_offer'
  post 'checkout/process_payment', to: 'checkout#process_payment'
  
  # Payment routes
  get 'payment/:id', to: 'checkout#payment', as: 'payment'
  post 'payment/:id/callback', to: 'checkout#payment_callback', as: 'payment_callback'
  
  # Gateway-specific payment routes
  get 'payment/:gateway/:id', to: 'checkout#payment', as: 'gateway_payment'
  get 'payment/:gateway/callback/:id', to: 'checkout#payment_callback', as: 'gateway_payment_callback'
  post 'payment/:gateway/callback/:id', to: 'checkout#payment_callback'
  post 'payment/:gateway/webhook', to: 'checkout#payment_webhook', as: 'gateway_payment_webhook'
  
  # Order routes
  resources :orders, only: [:index, :new, :create, :show]
  
  # Feature routes
  resources :features, only: [:index, :show] do
    member do
      post :subscribe
      post :start_trial
      post :cancel_subscription
    end
    collection do
      get :my_features
      get :dashboard
    end
  end
  
  # Subscription routes
  resources :subscriptions, only: [:show, :update, :destroy] do
    member do
      post :cancel
      post :suspend
      post :reactivate
      post :upgrade
      post :downgrade
    end
  end
  
  # Feature-specific routes
  namespace :whatsapp_marketing do
    get '/', to: 'whatsapp_marketing#index'
    get 'campaigns', to: 'whatsapp_marketing#campaigns'
    post 'campaigns', to: 'whatsapp_marketing#create_campaign'
    post 'send_message', to: 'whatsapp_marketing#send_message'
    get 'contacts', to: 'whatsapp_marketing#contacts'
    post 'import_contacts', to: 'whatsapp_marketing#import_contacts'
    get 'analytics', to: 'whatsapp_marketing#analytics'
    get 'templates', to: 'whatsapp_marketing#templates'
    post 'templates', to: 'whatsapp_marketing#create_template'
  end
  
  # API endpoints for contact form
  post 'contact/submit', to: 'home#submit_contact'
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Health check endpoint
  get "health" => "health#index"
end
