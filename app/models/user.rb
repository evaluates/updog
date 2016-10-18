class User < ActiveRecord::Base
  has_many :sites, :foreign_key => :uid, :primary_key => :uid
  has_many :subscriptions
  def self.subscribe email
    begin
      gibbon = Gibbon::Request.new(api_key: ENV['mailchimp_api_key'])
      gibbon.lists(ENV['mailchimp_list_id']).members.create(body: {email_address: email, status: "subscribed", merge_fields: {}})
    rescue
      logger.fatal "Failed to subscribe user - #{email}"
    end
  end
  def self.create_with_omniauth( email, uid, name )
	self.subscribe email
	ContactMailer.send_welcome(email).deliver_now!
	create! do |user|
	  user.email = email
	  user.provider = 'dropbox'
	  user.uid = uid
	  user.name = name
	end
    end
  def is_pro?
    self.subscriptions.where('active_until > ?', Time.now).any?
  end
end
