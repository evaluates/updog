class User < ActiveRecord::Base
  has_many :sites, :foreign_key => :uid, :primary_key => :uid
  has_one :upgrading
  def self.subscribe email
    begin
      Drip.subscribe email
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
  def blacklisted?
    email_without_dots = self.email.gsub(/\./,'')
    ENV['blacklist'] ||= ''
    ENV['blacklist'].split(',').include? email_without_dots
  end
  def self.created_today
    where("created_at > ?", Time.now.beginning_of_day)
  end
end
