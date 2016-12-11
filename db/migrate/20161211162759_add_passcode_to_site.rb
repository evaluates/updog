class AddPasscodeToSite < ActiveRecord::Migration
  def change
    add_column :sites, :encrypted_passcode, :string
  end
end
