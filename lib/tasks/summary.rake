namespace :summary do
  desc "Send a daily summary of new sites and users"
  task send: :environment do
    ContactMailer.daily_summary.deliver_now!
  end

end
