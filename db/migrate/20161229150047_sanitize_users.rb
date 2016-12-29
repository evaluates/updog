class SanitizeUsers < ActiveRecord::Migration
  def change
    remove_column :users, :provider, :string
    remove_column :users, :uid, :string
    remove_column :users, :email, :string
    remove_column :users, :name, :string
  end
end
