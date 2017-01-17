require 'spec_helper'

describe ApplicationController do
  before do
    @a = ApplicationController.new
    stub_request(:post, "https://api.dropboxapi.com/2/files/list_folder").
      to_return(:status => 200, :body => "{}", :headers => {})
  end
  it "gets dropbox files" do
    expect(@a.dropbox_files("","")).to eq({:error=>"missing access token"})
    expect(@a.dropbox_files("","abc")).to eq([])
  end
  it "gets dropbox folders" do
    expect(@a.dropbox_folders("","abc")).to eq([])
  end
  it "has a current_user" do
    @user = User.create
    sesh = {}
    sesh['user_id'] = @user.id
    allow(@a).to receive(:session){ sesh }
    allow(@a).to receive(:cookies){ {stub_user_id: @user.id} }
    expect(@a.current_user).to be_an_instance_of(User)
  end
end
