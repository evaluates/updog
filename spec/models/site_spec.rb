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
  it "has a base path" do
    s = Site.new(name: 'ohwow')
    expect(s.base_path).to eq('/ohwow')
    s.db_path = "/coobly"
    expect(s.base_path).to eq('/coobly')
    s.document_root = "/wow"
    expect(s.base_path).to eq('/wow')
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
  describe "CNAME configuration" do
    context "site has no domain" do
      it "doesn't do anything" do
        @s = Site.new name: 'pizza'
        expect(@s.domain_configuration).to be(nil)
        @s = Site.new name: 'pizza', domain: ''
        expect(@s.domain_configuration).to be(nil)
      end
    end
    it "gets a cname from a domain" do
      @s = Site.new name: 'pizza', domain: 'www.jshawl.xyz'
      expect(@s.domain_cname).to eq("updog.co")
    end
    it "has a protocol" do
      s = Site.new name: 'pizza'
      expect(s.protocol).to eq('https://')
      s.domain = 'www.pizza.com'
      expect(s.protocol).to eq('http://')
    end
    context "domain is configured correctly" do
      it "shows error when there is no CNAME entry" do
        @s = Site.new name: 'pizza', domain: 'www.pizza.com'
        allow(@s).to receive(:domain_cname){nil}
        expect(@s.domain_configuration[:text]).to eq("There is no CNAME entry for #{@s.domain}")
        expect(@s.domain_configuration[:klass]).to eq("red")
      end
      it "shows error when there is a CNAME entry but it's not updog.co" do
        @s = Site.new name: 'pizza', domain: 'www.google.com'
        allow(@s).to receive(:domain_cname){'notupdog.co'}
        expect(@s.domain_configuration[:text]).to eq("The CNAME entry for #{@s.domain} does not point to updog.co")
        expect(@s.domain_configuration[:klass]).to eq("red")
      end
      it "shows no error when there is a CNAME entry that's updog.co" do
        @s = Site.new name: 'pizza', domain: 'www.google.com'
        allow(@s).to receive(:domain_cname){'updog.co'}
        expect(@s.domain_configuration[:text]).to eq("You have configured your domain correctly.")
        expect(@s.domain_configuration[:klass]).to eq("green")
      end
    end
  end

 end
