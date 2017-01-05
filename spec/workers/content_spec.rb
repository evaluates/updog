require 'spec_helper'

describe ContentWorker do
  it "peforms admirably" do
    Site.destroy_all
    @u = User.create
    @u.identities.create!(provider: 'dropbox', email:'test@test.test')
    site = @u.sites.create!(provider:'dropbox', name: 'jjohn')
    worker = ContentWorker.new
    last_updated = site.dup.updated_at
    stub site.name, '/index.html', 200
    worker.perform site.id, '/index.html', 'abcdefg'
    expect(last_updated).not_to eq(site.updated_at)
  end
end
