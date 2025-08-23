Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  
  scope :weather do
    get '/',       to: 'weather#home',     as: :weather_home
    get :forecast, to: 'weather#forecast', as: :weather_forecast
  end
end
