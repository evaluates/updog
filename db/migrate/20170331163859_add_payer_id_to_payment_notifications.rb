class AddPayerIdToPaymentNotifications < ActiveRecord::Migration
  def change
    add_column :payment_notifications, :payer_id, :string
  end
end
