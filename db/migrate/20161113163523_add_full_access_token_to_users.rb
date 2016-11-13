class AddFullAccessTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :full_access_token, :string
  end
end
