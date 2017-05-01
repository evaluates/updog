class SessionsController < ApplicationController
  def new
    if params[:full]
      redirect_uri = ENV['db_full_callback']
      client_id = ENV['db_full_key']
      redirect_to "https://www.dropbox.com/oauth2/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
    else
      redirect_uri = ENV['db_callback']
      client_id = ENV['db_key']
      redirect_to "https://www.dropbox.com/oauth2/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
    end
  end
  def index
    if session['access_token'] != ''
      @user = get_dropbox_client.account_info['display_name']
    end
  end
  def create
    if params[:provider] == "dropbox"
      return redirect_to root_path if params[:error] == "access_denied"
      uid, name, email, access_token, full_access_token = dropbox_info params
    end
    if params[:provider] == "google"
      auth = request.env["omniauth.auth"]
      uid = auth["uid"]
      name = auth["info"]["name"]
      email = auth["info"]["email"]
      refresh_token = auth["credentials"]["refresh_token"]
      access_token = auth["credentials"]["token"]
    end
    @identity = Identity.find_by(uid: uid, provider: params[:provider])
    if current_user.nil? && @identity.nil?
      set_current_user User.create
    end
    if @identity.nil?
      @identity = current_user.identities.create(
        uid: uid,
        provider: params[:provider],
        refresh_token: refresh_token,
        name: name,
        email: email
      )
    end
    set_current_user @identity.user
    if full_access_token.nil?
      @identity.update(access_token: access_token)
    else
      @identity.update(full_access_token: full_access_token)
    end
    if current_user && current_user.blacklisted?
      @identity.user.destroy
      raise 'An error has occured'
    end
    if session[:back_to]
      redirect_to session[:back_to]
    else
      redirect_to '/'
    end
  end

  def dropbox_info params
    if params[:full]
      db_key = ENV['db_full_key']
      db_secret = ENV['db_full_secret']
      db_callback = ENV['db_full_callback']
    else
      db_key = ENV['db_key']
      db_secret = ENV['db_secret']
      db_callback = ENV['db_callback']
    end
    begin
      url = "https://api.dropboxapi.com/oauth2/token"
      opts = {
          body: {
            code: params[:code],
        	  grant_type: 'authorization_code',
        	  client_id: db_key,
        	  client_secret: db_secret,
        	  redirect_uri: db_callback
          }
        }
      res = HTTParty.post(url, opts)
      res = JSON.parse(res)
      if params[:full]
        full_access_token = res["access_token"]
      else
        access_token = res["access_token"]
      end
      account_id = res["account_id"]
      uid = res["uid"]
    rescue => e
      logger.error "Dropbox Error"
      logger.error e.message
      logger.error e.backtrace.join("\n")
      return redirect_to root_url
    end
    url = "https://api.dropboxapi.com/2/users/get_account"
    opts = {
      headers: {
        'Authorization' => "Bearer #{access_token}",
      	'Content-Type' => 'application/json'
      },
      body: {
        account_id: account_id
      }.to_json
    }
    res = HTTParty.post(url, opts)
    name = res['name']['display_name']
    email = res['email']
    return uid, name, email, access_token, full_access_token
  end

  def destroy
    session.clear
    redirect_to root_url
  end

  def unlink
    @identity = Identity.find_by(provider:params[:provider], user: current_user)
    @identity.destroy!
    session.clear unless current_user.identities.any?
    redirect_to :back
  end

end
