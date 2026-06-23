Rails.application.routes.draw do
  namespace :api do
    resources :test_results
  end
end
