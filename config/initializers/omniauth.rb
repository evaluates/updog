Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["google_client_id"], ENV["google_client_secret"], {
    name: 'google',
    scope: 'email, profile, drive, userinfo.email, userinfo.profile',
    access_type: 'offline',
    prompt: 'consent'
  }
end
