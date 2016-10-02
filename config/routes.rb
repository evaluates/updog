Rails.application.routes.draw do
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/', to: 'sites#load', constraints: { subdomain: /.+/, domain:'updog.co' }, via: [:get, :post, :put, :patch, :delete]
  match '/', to: 'sites#load', constraints: { subdomain: /.+updog-staging/, domain:'herokuapp.com' }, via: [:get, :post, :put, :patch, :delete]
  root 'sites#index'
  get '/logout', to: 'sessions#destroy'
  get '/auth/dropbox', to: 'sessions#new'
  get '/news/css/main.css', to: 'news#css'
  get '/news/:path', to: 'news#show'
  get '/news', to: 'news#index'
  resources :subscriptions
  match '/*req', to: 'sites#load', constraints: { subdomain: /.+/, domain: 'updog.co' }, via: [:get, :post, :put, :patch, :delete]
  match '/*req', to: 'sites#load', constraints: { subdomain: /.+updog-staging/, domain:'herokuapp.com' }, via: [:get, :post, :put, :patch, :delete]
  get '/about', to: 'pages#about'
  get '/source', to: 'pages#source'
  get '/contact', to: 'pages#contact'
  post '/contact', to: 'pages#contact_create'
  get '/pricing', to: 'pages#pricing'
  get '/admin', to: 'pages#admin'
  get '/webhook', to: 'webhook#challenge'
  post '/webhook', to: 'webhook#post'
  post "/versions/:id/revert", to: "versions#revert", as: "revert_version"
  post "/checkout", to: "subscriptions#checkout"

  resources :sites, path: ''

end
