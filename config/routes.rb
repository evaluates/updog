Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  get '/webhook', to: 'webhook#challenge'
  post '/webhook', to: 'webhook#post'
  resources :payment_notifications, only: [:create]
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match 'auth/:provider', to: 'sessions#unlink', via: [:delete]
  match '/', to: 'sites#load', constraints: { subdomain: /.+/}, via: [:get, :put, :patch, :delete]
  match '/*req', to: 'sites#load', constraints: { subdomain: /.+/}, via: [:get, :put, :patch, :delete]
  post '/verify', to: 'sites#passcode_verify'
  match '/', to: 'sites#send_contact', constraints: { subdomain: /.+/}, via: [:post]
  match '/*req', to: 'sites#send_contact', constraints: { subdomain: /.+/}, via: [:post]
  root 'sites#index'
  get '/logout', to: 'sessions#destroy'
  get '/auth/dropbox', to: 'sessions#new'
  get '/news/css/main.css', to: 'news#css'
  get '/news/:path', to: 'news#show'
  get '/news', to: 'news#index'
  resources :reviews

  get '/about', to: 'pages#about'
  get '/faq', to: 'pages#faq'
  get '/tos', to: 'pages#tos'
  get '/source', to: 'pages#source'
  get '/contact', to: 'pages#contact'
  post '/contact', to: 'pages#contact_create'
  get '/thanks', to: 'pages#thanks'
  get '/pricing', to: 'pages#pricing'
  get '/feedback', to: 'pages#feedback'
  post '/feedback', to: 'pages#feedback_create'
  get '/folders', to: 'sites#folders'
  get '/files', to: 'sites#files'
  get '/admin', to: 'pages#admin'
  get '/account', to: 'pages#account'

  post "/versions/:id/revert", to: "versions#revert", as: "revert_version"
  post "/checkout", to: "payments#checkout"
  resources :sites, path: '' do
    delete 'password'
  end
  namespace :api do
    get '/dropbox/files', to: 'dropbox#files'
    get '/dropbox/folders', to: 'dropbox#folders'
    get '/google/files', to: 'google#files'
    get '/google/folders', to: 'google#folders'
  end
end
