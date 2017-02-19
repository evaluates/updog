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
  def dropbox_files path = nil, access_token = nil
    path = path || params[:path] ||""
    at = access_token || params[:access_token] || ""
    if at.blank?
      return {
        error: "missing access token"
      }
    end
    url = 'https://api.dropboxapi.com/2/files/list_folder'
    opts = {
      headers: {
        'Authorization' => 'Bearer ' + at,
        'Content-Type' => 'application/json'
      },
      body: {
        path: path,
      }.to_json
    }
    res = HTTParty.post(url, opts)
    if res.body.match("error")
      return {error: res}
    end
    res.body
    entries = JSON.parse(res.body)["entries"] || []
    entries.sort_by{ |entry|
      entry['name']
    }.reject{|entry|
      entry["name"] == 'directory-index.html'
    }

  end

  def dropbox_folders path = nil, access_token = nil
    content = dropbox_files path, access_token
    content.select{|entry|
      entry[".tag"] == "folder"
    }.sort_by{|folder| folder["name"] }
  end

  private
  def set_admin
    @admin = "admin" if current_user && current_user.email == "jesseshawl@gmail.com"
  end
end
