class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_admin
  helper_method :current_user
  def current_user
    return nil unless session['user_id']
    iden = Identity.find_by( uid: session['user_id'] )
    return iden.user if iden
  end
  private
  def set_admin
    @admin = "admin" if current_user && current_user.email == "jesseshawl@gmail.com"
  end
end
