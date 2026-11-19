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
    resources :partners
    resources :sellers do
      member do
        put :approve
        put :reject
        put :suspend
      end
    end
  end
end
