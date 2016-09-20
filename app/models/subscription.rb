class Subscription < ActiveRecord::Base
  belongs_to :user
  def renew
    update(active_until: self.active_until + 1.month)
  end
  def notify
    ContactMailer.notify(self.user.email).deliver_now!
  end
end
