class Identity < ActiveRecord::Base
  belongs_to :user
  after_create :subscribe
  def subscribe
    if user.identities.length < 2 # if the first one
      begin
        Drip.subscribe email
      rescue => e
        logger.error "Failed to subscribe user - #{email}"
        logger.error e.message
        logger.error e.backtrace.join("\n")
      end
    end
  end
end
