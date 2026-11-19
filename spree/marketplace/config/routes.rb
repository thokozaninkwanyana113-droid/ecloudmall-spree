Spree::Core::Engine.add_routes do
  namespace :api, defaults: { format: 'json' } do
    namespace :v3 do
      namespace :store do
        resources :sellers, only: [:index, :show]
        resources :seller_applications, only: [:create]
      end
    end
  end

  namespace :admin do
    resources :sellers do
      member do
        put :approve
        put :reject
        put :suspend
      end
    end
  end
end
