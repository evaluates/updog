class Drip
  def self.subscribe email
    acct_id = ENV['drip_account']
    campaign_id = ENV['drip_campaign']
    identity = Identity.find_by_email(email)
    begin
      name = identity.name.split(' ').first
    rescue
      name = ''
      Rails.logger.error('name issue')
      p identity
    end
    headers = {
      'User-Agent' => 'UpDog (updog.co)',
      'Content-Type' => 'application/vnd.api+json'
    }
    body = {
      :subscribers => [{
        email: email,
        time_zone: "Ameriza/New_York",
        custom_fields: {
          name: name
        }
      }
    ]}.to_json
    opts = {
      headers: headers,
      basic_auth: { username: ENV['drip_token']},
      body: body
    }
    HTTParty.post(
     "https://api.getdrip.com/v2/#{acct_id}/campaigns/#{campaign_id}/subscribers",
     opts
    )
  end
  def self.event email, action
      acct_id = ENV['drip_account']
      opts = {
        headers: {
	  'User-Agent' => 'UpDog (updog.co)',
	  'Content-Type' => 'application/vnd.api+json'
       },
	basic_auth: { username: ENV['drip_token']},
	body: {
	  events: [{
	    email: email,
	    action: action
	  }]
	}.to_json
      }
      HTTParty.post(
	"https://api.getdrip.com/v2/#{acct_id}/events",
	opts
      )
  end
end
