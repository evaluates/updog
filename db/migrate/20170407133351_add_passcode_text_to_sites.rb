class AddPasscodeTextToSites < ActiveRecord::Migration
  def change
    add_column :sites, :passcode_text, :string
  end
end
