RequestTracker::Engine.routes.draw do
  resources :requests, only: [:index, :show] do
    collection do
      get :grouped
    end
  end

  resources :error_logs, only: [:index, :show] do
    collection do
      patch :hide
      patch :unhide
    end
  end

  resources :job_logs, only: [:index, :show]
  resources :mailer_logs, only: [:index, :show]
  resources :saved_searches, only: [:create, :destroy]

  root to: "requests#index"
end
