require 'spec_helper'

describe Identity do
  before do
    Identity.destroy_all
    User.destroy_all
    @user = User.create
    @identity1 = @user.identities.create! email: 'jesse@jshawl.com', name: 'Jesse'
    @identity2 = @user.identities.create! email: 'jesse2@jshawl.com', name: 'jesse'
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token").
      to_return(:status => 200, :body => "{\"access_token\":\"hijklmn\"}", :headers => {})
  end
  it "refreshes the access_token" do
    old_access_token = 'abcdefg'
    @identity1.refresh_access_token
    expect(@identity1.access_token).to eq('hijklmn')
  end
end
