require 'spec_helper'

describe PagesController, type: 'feature' do
  before :each do
    Capybara.default_host = 'http://example.com'
  end
  it "has pricing" do
    visit "/pricing"
    expect(page).to have_content('19.99')
  end
  it "supports coupon codes" do
    visit "/pricing?code=" + ENV['coupon_code']
    expect(page).to have_content(' 9.99')
  end
  it "remembers the coupon" do
    visit "/pricing?code=" + ENV['coupon_code']
    visit "/faq"
    expect(page).to have_content(' 9.99')
  end
end
