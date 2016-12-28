class AddCollectionUrlToSites < ActiveRecord::Migration
  def change
    add_column :sites, :google_id, :string
  end
end
