class CreateIdentities < ActiveRecord::Migration
  def change
    create_table :identities do |t|
      t.integer :uid
      t.string :provider
      t.string :name
      t.string :email
      t.string :access_token
      t.string :full_access_token
      t.references :user, index: true, foreign_key: true
      t.timestamps
    end
  end
end
