class Upgrading < ActiveRecord::Base
  belongs_to :user
  after_create :notify_drip
  def self.created_on datetime
    where("created_at > ? and created_at < ?", datetime.beginning_of_day, datetime.end_of_day)
  end
  private
  def notify_drip
    Drip.event self.user.email, "upgraded"
  end
end
