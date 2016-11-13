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
      access_token = res["access_token"]
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
    name = res['display_name']
    email = res['email']
    user = User.find_by_provider_and_uid('dropbox', uid) || User.create_with_omniauth(email, uid, name)
    if user.blacklisted?
      user.destroy
      raise 'An error has occured'
    end
    if params[:full]
      user.full_access_token = access_token
    else
      session[:user_id] = uid
      session[:access_token] = access_token
      session[:user_name] = name
      user.access_token = access_token
    end
    user.save
    if session[:back_to]
      redirect_to session[:back_to]
    else
      redirect_to '/'
    end
  end
  def destroy
    session.clear
    redirect_to root_url
  end
end
