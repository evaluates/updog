describe "Checking a domain's configuration", :type => :feature do
  let(:current_user){@u}
  before do
    Site.destroy_all
    @u = User.create! is_pro: true
    @u.identities.create!(provider: 'dropbox', email:'test@test.test')
    @site = @u.sites.create!(provider:'dropbox', name: 'jjjjohn', domain: 'www.pizza.com')
    Capybara.default_host = 'http://example.com'
  end

  it "loads the index" do
    visit root_path
    expect(page).to have_content 'Create New Site'
  end
  it "loads the edit page" do
    visit edit_site_path(@site)
    expect(page).to have_content 'settings'
  end
  it "can create new sites" do
    visit '/new'
    page.find('#site_name').set("pizzajam")
    click_button 'Save'
    save_and_open_page
    current_path.should == site_path(Site.last)
  end
  it "has domain configuration status when theres a domain" do
    visit edit_site_path(@site)
    expect(page).to have_css '.domain-configuration-status'
  end
end
