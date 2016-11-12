class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_admin
  def current_user
    User.find_by( access_token: session['access_token'] )
  end
  private
  def set_admin
    @admin = "admin" if current_user && current_user.email == "jesseshawl@gmail.com"
  end
end
