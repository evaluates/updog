class AddContactEmailToSites < ActiveRecord::Migration
  def change
    add_column :sites, :contact_email, :string
  end
end
