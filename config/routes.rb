def load? request
    request.env['SERVER_NAME'] == 'localhost' || request.env['SERVER_NAME'] == 'updog.co'
end
class RequestConstraint
  def matches? request
    load? request
  end
end

class LoadConstraint
  def matches? request
    !load? request
  end
end

Rails.application.routes.draw do
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/', to: 'sites#index', constraints: RequestConstraint.new, via: [:get,:post,:put,:patch,:delete]
  match '/', to: 'sites#load', via: [:get, :post, :put, :patch, :delete]
  match '/*req', to: 'sites#load', constraints: LoadConstraint.new, via: [:get, :post, :put, :patch, :delete]
  root 'sites#index'
  get '/logout', to: 'sessions#destroy'
  get '/auth/dropbox', to: 'sessions#new'
  get '/news/css/main.css', to: 'news#css'
  get '/news/:path', to: 'news#show'
  get '/news', to: 'news#index'
  resources :payments
  get '/about', to: 'pages#about'
  get '/source', to: 'pages#source'
  get '/contact', to: 'pages#contact'
  post '/contact', to: 'pages#contact_create'
  get '/pricing', to: 'pages#pricing'
  get '/admin', to: 'pages#admin'
  get '/webhook', to: 'webhook#challenge'
  post '/webhook', to: 'webhook#post'
  post "/versions/:id/revert", to: "versions#revert", as: "revert_version"
  post "/checkout", to: "payments#checkout"
  resources :sites, path: ''
end
