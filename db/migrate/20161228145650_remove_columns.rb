class RemoveColumns < ActiveRecord::Migration
  def change
    remove_column :users, :access_token
    remove_column :users, :full_access_token
  end
end
