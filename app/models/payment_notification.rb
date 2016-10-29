class PaymentNotification < ActiveRecord::Base
  belongs_to :user
  serialize :params
  after_create :upgrade_user
  private
  def upgrade_user
    if status == "Completed"
      user.update_attribute(:is_pro, true)
    end
  end
end
