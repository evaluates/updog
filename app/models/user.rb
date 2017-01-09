class User < ActiveRecord::Base
  has_many :sites
  has_many :identities
  has_one :upgrading
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
  def full_access_token
  end
end
