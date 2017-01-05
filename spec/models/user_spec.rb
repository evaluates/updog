require 'spec_helper'

describe User do
  before do
    Identity.destroy_all
    User.destroy_all
    @user = User.create
    @identity1 = @user.identities.create! email: 'jesse@jshawl.com', name: 'Jesse'
    @identity2 = @user.identities.create! email: 'jesse@jshawl.com', name: 'jesse'
  end
  it "can be blacklisted" do
    ENV['blacklist'] = 'jesse@jshawlcom'
    expect(@user.blacklisted?).to eq(true)
  end
  it "has a name" do
    expect(@user.name).to eq('Jesse')
  end
  it "can get all the users from a particular day" do
    expect(User.created_on(Time.now.end_of_day).count).to eq(1)
  end
end
