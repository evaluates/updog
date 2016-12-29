class RemoveUnusedColumns < ActiveRecord::Migration
  def change
    remove_column :sites, :uid
    remove_column :users, :provider, :string
    remove_column :users, :name, :string
  end
end
