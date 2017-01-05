class Identity < ActiveRecord::Base
  belongs_to :user
  after_create :subscribe
  def subscribe
    if user.identities.length < 2 # if the first one
      Drip.subscribe email
    end
  end
  def refresh_access_token
    opts = { body: {
        client_id: ENV['google_client_id'],
        client_secret: ENV['google_client_secret'],
        refresh_token: self.refresh_token,
        grant_type: 'refresh_token'
      }
    }
    res = JSON.parse(HTTParty.post('https://www.googleapis.com/oauth2/v4/token', opts).body)
    update(access_token: res["access_token"])
    self.access_token
  end
end
