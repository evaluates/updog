require 'dropbox_sdk'
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :redirect_custom_domain_from_https

  def get_client at
    return DropboxClient.new(at)
  end

  def current_user
    User.find_by( access_token: session['access_token'] )
  end

  def redirect_custom_domain_from_https
    if env['rack.url_scheme'] == "https"
      host = env['HTTP_HOST'] + env['REQUEST_URI']
      redirect_to 'http://' + host
    end
  end

end
