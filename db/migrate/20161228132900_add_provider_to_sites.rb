class AddProviderToSites < ActiveRecord::Migration
  def change
    add_column :sites, :provider, :string
    Site.update_all(provider: 'dropbox')
  end
end
