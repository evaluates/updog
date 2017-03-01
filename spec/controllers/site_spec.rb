require 'spec_helper'

describe SitesController, type: 'controller' do
  before :each do
    Identity.destroy_all
    Site.destroy_all
    User.destroy_all
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    @u = User.create! is_pro: true
    @u.identities.create!(provider: 'google', email:'test@test.test')
    @site = @u.sites.create!(provider:'dropbox', name: 'jjjjjohn', domain: 'www.pizza.com')
    @request.env["REQUEST_PATH"] = '/'
    @request.host = @site.domain
    @request.env['HTTP_REFERER'] = @site.domain
  end
  it "doesnt do anything if path ends in .php" do
    @request.env["REQUEST_PATH"] = '/wp-admin.php'
    post :send_contact
    expect(response.body).to eq('')
    expect(ActionMailer::Base.deliveries.count).to eq(0)
  end
  it "renders nothing if form not sent from same domain" do
    @request.env['HTTP_REFERER'] = 'google.com'
    post :send_contact
    expect(response.body).to eq('')
  end
  it "redirects back if the user isn't pro" do
    @u.update(is_pro: false)
    post :send_contact
    expect(response).to redirect_to @site.link
    expect(ActionMailer::Base.deliveries.count).to eq(0)
  end
  it "uses the sites contact email if available" do
    @site.update(contact_email:'jesse@jshawl.com')
    post :send_contact
    expect(ActionMailer::Base.deliveries.last.to[0]).to eq("jesse@jshawl.com")
  end
  it "falls back to the creators email" do
    post :send_contact
    expect(ActionMailer::Base.deliveries.last.to[0]).to eq("test@test.test")
  end
  it "redirects if param present" do
    post :send_contact, redirect: 'http://google.com/'
    expect(response).to redirect_to 'http://google.com/'
  end
  it "fails silently" do
    @request.env['HTTP_REFERER'] = nil
    post :send_contact
    expect(response.body).to eq('')
  end
end
