Spree::Core::Engine.add_routes do
  namespace :api, defaults: { format: 'json' } do
    namespace :v3 do
      namespace :store do
        resources :sellers, only: [:index, :show]
        resources :seller_applications, only: [:create]
        get 'delivery_methods/:delivery_method_id/pickup_points', to: 'pickup_points#index', as: :delivery_method_pickup_points
        patch 'carts/:cart_id/fulfillments/:fulfillment_id/pickup_point', to: 'carts/pickup_points#update', as: :cart_fulfillment_pickup_point
      end
    end
  end

  namespace :admin do
    resources :partners do
      member { put :close_month }
      resource :bank_account, only: [:update] do
        put :verify
      end
    end
    resource :finance, only: [:show], controller: 'finance' do
      post :sync
    end
    resources :payout_batches, only: [:index, :show, :create] do
      member do
        put :approve
        put :cancel
        put :mark_paid
        get :export
      end
    end
    resources :payouts, only: [] do
      member { put :mark_failed }
    end
    resources :sellers do
      resource :bank_account, only: [:update] do
        put :verify
      end
      member do
        put :approve
        put :reject
        put :suspend
      end
    end
  end
end
