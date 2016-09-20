class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :stripe_id
      t.references :user
      t.datetime :active_until
    end
  end
end
