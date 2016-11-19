namespace :summary do
  desc "Send a daily summary of new sites and users"
  task send: :environment do
    ContactMailer.daily_summary.deliver_now!
  end
end
namespace :request_count do
  desc "Count number of requests"
  task write: :environment do
    File.write(Rails.root.join('tmp/request-count.txt'),Click.all.count)
  end
end
