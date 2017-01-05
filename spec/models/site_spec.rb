require_relative '../rails_helper'
ActiveRecord::Base.logger = nil


describe Site do
  before do
    Site.destroy_all
    Identity.destroy_all
    User.destroy_all
    @u = User.create
    @u.identities.create!(access_token:ENV['db_access_token'], provider: 'dropbox', email:'test@test.test')
  end
  it "should have a name" do
    s = Site.new( name: 'jjohn' )
    expect(s.name).to eq('jjohn')
  end
  it "should have a domain" do
    s = @u.sites.create(provider:'dropbox', name: 'jjohn')
    expect(s.subdomain).to eq('jjohn.updog.co')
    s.destroy
  end
  it "should have a subdomain" do
    s = @u.sites.create(provider:'dropbox', name: '&& Pizzal -' )
    expect(s.subdomain).to eq('pizzal.updog.co')
    s.destroy
  end
  it "should replace non-word chars" do
    s = @u.sites.create(provider:'dropbox', name: 'Jimmy Johns' )
    expect(s.name).to eq('jimmy-johns')
    s.destroy
  end
  it "should not end with a hyphen" do
    s = @u.sites.create(provider:'dropbox', name: 'Jimmy Johns!' )
    expect(s.name).to eq('jimmy-johns')
    s.destroy
  end
  it "should not end with a hyphen" do
    s = @u.sites.create(provider:'dropbox', name: 'Jimmy Johns!!!' )
    expect(s.name).to eq('jimmy-johns')
    s.destroy
  end
  it "should not start with a hyphen" do
    s = @u.sites.create(provider:'dropbox', name: '!!!Jimmy Johns!!!' )
    expect(s.name).to eq('jimmy-johns')
    s.destroy
  end
  it "'s domain shouldnt contain updog.co" do
    s = Site.new( name: "onew" )
    s.domain = "overrideusername.updog.co"
    expect(s.valid?).to eq(false)
  end
  it "'s domain should be a subdomain" do
    s = Site.new( name: "onew" )
    s.domain = "pizza.co"
    expect(s.valid?).to eq(false)
  end
  it "'s domain should be a subdomain" do
    s = Site.new( name: "onew" )
    s.domain = "www.pizza.co"
    expect(s.valid?).to eq(true)
  end
  it "'s domain should be a subdomain" do
    s = Site.new( name: "onew" )
    s.domain = "www.pizza-jam.co"
    expect(s.valid?).to eq(true)
  end
  it "encrypts a passcode" do
    s = Site.new( passcode: "onew" )
    s.encrypt_password
    expect(s.encrypted_passcode).not_to be(nil)
  end
  it "has a nice url f'sho" do
    s = @u.sites.create( name: 'hotdog' )
    expect(s.to_param).to eq("#{s.id}-hotdog")
  end
  it "has a link" do
    s = @u.sites.create( name: 'pizza' )
    expect(s.link).to eq('pizza.updog.co')
    s.domain = 'www.pizza.com'
    expect(s.link).to eq('www.pizza.com')
  end
  it "injects a lil html" do
    s = @u.sites.create( name: 'pizza2' )
    expect(s.inject?).to eq(true)
  end
  it "shows sites created today" do
    expect(Site.created_today.is_a? ActiveRecord::Relation).to eq(true)
  end
  it "shows clicks today" do
    s = Site.new
    expect(s.clicks_today.is_a? ActiveRecord::Relation).to eq(true)
  end
  it "shows popular sites" do
    expect(Site.popular.is_a? ActiveRecord::Relation).to eq(true)
  end
end
