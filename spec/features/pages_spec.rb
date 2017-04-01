describe PagesController, type: 'feature' do
  before :each do
    Capybara.default_host = 'http://example.com'
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    @u = User.create! is_pro: true
    @u.identities.create!(provider: 'google', email:'test@test.test')
  end
  it "has pricing" do
    visit "/pricing"
    expect(page).to have_content('10.00')
    visit "/faq"
    expect(page).to have_content('10.00')
  end
  it "receives feedback" do
    visit "/feedback"
    fill_in 'how', with: 'n/a'
    find('button').click
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end
  it "shows account" do
    visit "/account"
    expect(current_path).to eq('/')
    log_in @u
    visit "/account"
    expect(current_path).to eq('/account')
  end
  it "can submit contact form" do
    visit "/contact"
    find("button").click
    expect(page).to have_content('can’t')
    visit "/contact"
    fill_in 'email', with: 'jesse@jam.co'
    fill_in 'content', with: 'radical'
    find("button").click
    expect(page).to have_content('success')
  end
  it "has an admin page" do
    visit "/admin"
    expect(current_path).to eq("/")
    @u.identities.last.update(email:'jesseshawl@gmail.com')
    Upgrading.create!(user: @u)
    Stat.destroy_all
    Stat.create!(date: Date.today, new_upgrades: 2)
    log_in @u
    visit "/admin"
    expect(current_path).to eq("/admin")
    visit "/admin?email=jesseshawl@gmail.com"
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
