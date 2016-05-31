class User < ActiveRecord::Base
  has_many :sites, :foreign_key => :uid, :primary_key => :uid
  def self.subscribe email
    gibbon = Gibbon::Request.new(api_key: ENV['mailchimp_api_key'])
    gibbon.lists(ENV['mailchimp_list_id']).members.create(body: {email_address: email, status: "subscribed", merge_fields: {}})
  end
  def self.create_with_omniauth( email, uid, name )
	self.subscribe email
	create! do |user|
	  user.email = email
	  user.provider = 'dropbox'
	  user.uid = uid
	  user.name = name
	end
    end
end
