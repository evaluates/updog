class AddPasscodeLogoPathToSites < ActiveRecord::Migration
  def change
    add_column :sites, :passcode_logo_path, :string
  end
end
