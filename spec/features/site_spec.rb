describe "Sites Controller", :type => :feature do
  before do
    Site.destroy_all
    @u = User.create! is_pro: true
    @u.identities.create!(provider: 'google', email:'test@test.test')
    @u.identities.create!(provider: 'dropbox', email:'test@test.test', full_access_token: 'abcdefghijklmnopqrstuvwxyz')

    @site = @u.sites.create!(provider:'dropbox', name: 'jjjjohn', domain: 'www.pizza.com')
    Capybara.default_host = 'http://example.com'
    stub_request(:post, "https://api.dropboxapi.com/2/files/create_folder").to_return(:status => 200, :body => "", :headers => {})
    stub_request(:post, "https://content.dropboxapi.com/2/files/upload").to_return(:status => 200, :body => "", :headers => {})
    log_in @u
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
    choose('Dropbox')
    page.find('#site_name').set("pizzajam")
    click_button 'Save'
    expect(current_path).to eq(site_path(Site.last))

    visit '/new'
    choose('Dropbox')
    page.find('#site_name').set("pizzajammerston")
    page.find('#db_path').set("somethinhere")
    click_button 'Save'
    expect(current_path).to eq(site_path(Site.last))

    visit '/new'
    choose('Google')
    page.find('#site_name').set("pizzajammerston2")
    click_button 'Save'
    expect(current_path).to eq(site_path(Site.last))
  end
  it "renders new if there's an issue creating a site" do
    visit '/new'
    click_button 'Save'
    expect(page).to have_content('Name can\'t be blank')
  end
  it "can edit a site" do
    visit edit_site_path(@site)
    click_button 'Save'
    expect(current_path).to eq(site_path(Site.last))
  end
  it "renders edit if there's an issue updating a site" do
    visit edit_site_path(@site)
    page.find('#site_name').set("")
    click_button 'Save'
    expect(page).to have_content('Name can\'t be blank')
  end
  it "has domain configuration status when theres a domain" do
    visit edit_site_path(@site)
    expect(page).to have_css '.domain-configuration-status'
  end
  it "cannot create new sites if not pro" do
    @u.update(is_pro: false)
    visit '/new'
    expect(current_path).to eq(root_path)
  end
  it "handles ActiveRecord failures gracefully" do
    visit '/12345-kjahsd'
    expect(page).to have_content "Not Found"
  end
  it "can delete sites" do
    count_before = Site.count
    page.driver.submit :delete, site_path(@site), {}
    expect(Site.count + 1).to eq(count_before)
  end
  it "can load sites" do
    Capybara.default_host = "http://www.googly.com/"
    @u.sites.create(name:'somethingnotgoogly')
    visit '/'
    expect(page).to have_content('Not Found')
  end
  it "redirects to trailing slash" do
    Capybara.app_host = "http://#{@site.domain}/"
    stub_request(:post, "https://content.dropboxapi.com/2/files/download").
      with(:headers => {'Dropbox-Api-Arg'=>/\{"path":"\/jjjjohn\/dir"\}$/}).
      to_return(:status => 200, :body => "{\"error_summary\": \"path/not_file/.\", \"error\": {\".tag\": \"path\", \"path\": {\".tag\": \"not_file\"}}}", :headers => {})
    stub_request(:post, "https://content.dropboxapi.com/2/files/download").
      with(:headers => {'Dropbox-Api-Arg'=>/\{"path":"\/jjjjohn\/dirg"\}$/}).
      to_return(:status => 200, :body => "ok", :headers => {})
    visit '/dir'
    expect(current_path).to eq('/dirg')
  end
  it "can authenticate requests" do
    Capybara.app_host = "http://#{@site.domain}/"
    stub_request(:post, "https://content.dropboxapi.com/2/files/download").to_return(:status => 200, :body => "ok", :headers => {})
    @site.update(username: 'foo', passcode: 'bar')
    basic_auth('foo', 'bar')
    visit '/'
    expect(page).to have_content('ok')
  end
  it "can remove passcode protection" do
    page.driver.submit :delete, site_password_path(@site), {}
    Capybara.app_host = "http://#{@site.domain}/"
    stub_request(:post, "https://content.dropboxapi.com/2/files/download").to_return(:status => 200, :body => "ok", :headers => {})
    visit '/'
    expect(page).to have_content('ok')
  end
  it "can load dropbox folders for selection" do
    stub_request(:post, "https://content.dropboxapi.com/2/files/download").to_return(:status => 200, :body => "[]", :headers => {})
    visit folders_path + "?path=/&access_token=abc"
    expect(page).to have_content('[]')
  end
  it "can authenticate requests" do
    Capybara.app_host = "http://#{@site.domain}/"
    stub_request(:post, "https://content.dropboxapi.com/2/files/download").to_return(:status => 200, :body => "ok", :headers => {})
    @site.update(passcode: 'bar')
    visit '/'
    expect(page).to have_content('This site is protected with a passcode')
    fill_in 'passcode', with: 'baz'
    find('button').click
    expect(page).to have_content('Passcode incorrect')
    fill_in 'passcode', with: 'bar'
    find('button').click
    expect(page).to have_content('ok')
  end
  it "can customize passcode logo and text" do
    Capybara.app_host = "http://#{@site.domain}/"
    stub_request(:post, "https://content.dropboxapi.com/2/files/download").to_return(:status => 200, :body => "ok", :headers => {})
    @site.update(passcode: 'bar')
    visit '/'
    expect(page).to have_content('This site is protected with a passcode')
    expect(page).to have_css("img[src='https://updog.co/logo.png']")
    @site.update(passcode_logo_path:'/coolimg.jpg', passcode_text:'enter passcode')
    @site.reload
    visit '/'
    expect(page).to have_content('enter passcode')
    expect(page).to have_css("img[src='/coolimg.jpg']")
  end
  it "redirects to dropbox for zip files" do
      Capybara.app_host = "http://#{@site.domain}/"
      stub_request(:post, "https://api.dropboxapi.com/2/files/get_temporary_link").
         to_return(:status => 200, :body => fixture('get_temporary_link.json'), :headers => {})
      visit '/a.zip'
      expect(current_url).to match('dl.dropboxusercontent.com')
  end
  it "redirects to dropbox for epub files" do
      Capybara.app_host = "http://#{@site.domain}/"
      stub_request(:post, "https://api.dropboxapi.com/2/files/get_temporary_link").
         to_return(:status => 200, :body => fixture('get_temporary_link.json'), :headers => {})
      visit '/a.epub'
      expect(current_url).to match('dl.dropboxusercontent.com')
  end
end

def log_in current_user
  if Capybara.current_driver == :webkit
    page.driver.browser.set_cookie("stub_user_id=#{current_user.id}; path=/; domain=127.0.0.1")
  else
    cookie_jar = Capybara.current_session.driver.browser.current_session.instance_variable_get(:@rack_mock_session).cookie_jar
    cookie_jar[:stub_user_id] = current_user.id
  end
end
def basic_auth(name, password)
  if page.driver.respond_to?(:basic_auth)
    page.driver.basic_auth(name, password)
  elsif page.driver.respond_to?(:basic_authorize)
    page.driver.basic_authorize(name, password)
  elsif page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:basic_authorize)
    page.driver.browser.basic_authorize(name, password)
  else
    raise "I don't know how to log in!"
  end
end
