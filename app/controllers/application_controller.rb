class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_admin
  helper_method :current_user
  def current_user
    if Rails.env.test?
      session['user_id'] = cookies[:stub_user_id]
    end
    begin
      session['user_id'] ? User.find(session['user_id']) : nil
    rescue
      session.clear
      redirect_to root_path
      return nil
    end
  end
  def set_current_user user
    session["user_id"] = user.id
  end
  private
  def set_admin
    @admin = "admin" if current_user && current_user.email == "jesseshawl@gmail.com"
  end
end
