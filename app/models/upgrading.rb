class Upgrading < ActiveRecord::Base
  belongs_to :user
  after_create :notify_drip

  private
  def notify_drip
    Drip.event self.user.email, "upgraded"
  end
end
