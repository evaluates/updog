Rails.application.routes.draw do
  mount Split::Dashboard, at: 'splitabresults'
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
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
  resources :payments
  resources :reviews
  resources :payment_notifications, only: [:create]
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
  get '/admin', to: 'pages#admin'
  get '/webhook', to: 'webhook#challenge'
  post '/webhook', to: 'webhook#post'
  post "/versions/:id/revert", to: "versions#revert", as: "revert_version"
  post "/checkout", to: "payments#checkout"
  resources :sites, path: ''
end
