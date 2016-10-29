class CreatePaymentNotifications < ActiveRecord::Migration
  def change
    create_table :payment_notifications do |t|
      t.text :params
      t.references :user
      t.string :status
      t.string :transaction_id
    end
  end
end
