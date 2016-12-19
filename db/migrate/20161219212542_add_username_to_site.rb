class AddUsernameToSite < ActiveRecord::Migration
  def change
    add_column :sites, :username, :string
  end
end
