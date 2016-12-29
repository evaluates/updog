class User < ActiveRecord::Base
  has_many :sites
  has_many :identities
  has_one :upgrading
  after_create :subscribe
  def subscribe
    begin
      Drip.subscribe email
      gibbon = Gibbon::Request.new(api_key: ENV['mailchimp_api_key'])
      gibbon.lists(ENV['mailchimp_list_id']).members.create(body: {email_address: email, status: "subscribed", merge_fields: {}})
    rescue => e
      logger.error "Failed to subscribe user - #{email}"
      logger.error e.message
      logger.error e.backtrace.join("\n")
    end
  end
  def blacklisted?
    email_without_dots = self.email.gsub(/\./,'')
    ENV['blacklist'] ||= ''
    ENV['blacklist'].split(',').include? email_without_dots
  end
  def self.created_on datetime
    where("created_at > ? and created_at < ?", datetime.beginning_of_day, datetime.end_of_day)
  end
  def email
    identities.map(&:email).compact.first
  end
  def name
    identities.map(&:name).compact.first
  end
end
