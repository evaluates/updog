class CreateStats < ActiveRecord::Migration
  def change
    create_table :stats do |t|
      t.integer :new_users
      t.integer :new_upgrades
      t.float :percent_pro
      
      t.timestamps
    end
  end
end
