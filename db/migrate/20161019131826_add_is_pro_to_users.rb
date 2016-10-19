class AddIsProToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_pro, :boolean
  end
end
