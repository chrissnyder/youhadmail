Transcribe::Application.routes.draw do
  resources :templates

  root :to => 'asset_collections#index'

  match 'transcriptions/next' => 'transcriptions#next'
  match 'transcriptions/transcribe' => 'transcriptions#transcribe'
  match 'transcriptions/transcribe/:id' => 'transcriptions#transcribe'
  match 'transcriptions/by_user/:collection_id' => 'transcriptions#by_user'
  match 'transcriptions/terms/:entity_id/:field_key' => 'transcriptions#terms'
  match 'transcriptions/annotations' => 'transcriptions#annotations', defaults: { format: 'json' }
  resources :transcriptions
  resources :asset_collections do
		resources :annotations
	end
  resources :annotations

  match 'bio' => 'bio#fetch'

	match 'about' => 'home#about'
	match 'help' => 'home#help'

	match 'auth/login' => 'auth#login'
	match 'auth/info' => 'auth#info'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
