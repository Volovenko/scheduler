Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :tasks, only: %i[index show create update destroy] do
        resources :tags,        only: %i[create destroy], controller: "task_tags"
        resources :occurrences, only: %i[update destroy], controller: "task_occurrences", param: :date
      end
      resources :tags, only: %i[index create update destroy]
    end
  end
end
