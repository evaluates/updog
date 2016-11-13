class AddDbPathToSites < ActiveRecord::Migration
  def change
    add_column :sites, :db_path, :string
  end
end
