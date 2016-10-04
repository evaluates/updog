module ApplicationHelper
  def current_user
    User.find_by( access_token: session['access_token'] )
  end
end
