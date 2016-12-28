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
    @identity = Identity.find_by(uid: uid, provider: 'dropbox')
    if @identity.nil?
      @identity = Identity.create(uid: uid, provider: 'dropbox')
    end
    if current_user
      if @identity.user == current_user
        flash[:notice] = "Already linked that account!"
      else
        @identity.user = current_user
        @identity.save
        flash[:notice] = "Successfully linked that account!"
      end
    else
      if @identity.user.present?
        session["user_id"] = @identity.uid
        flash[:notice] = "Signed in!"
      else
        # No user associated with the identity so we need to create a new one
        user = User.create!
        @identity.user = current_user
        @identity.save
      end
    end
    if @identity.user.blacklisted?
      @identity.user.destroy
      raise 'An error has occured'
    end
    if params[:full]
      @identity.full_access_token = access_token
    else
      session[:user_id] = uid
      session[:access_token] = access_token
      session[:user_name] = name
      @identity.access_token = access_token
    end
    @identity.save
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
