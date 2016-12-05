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
namespace :stats do
  desc "Collect Stats"
  task collect: :environment do
    new_users = User.created_on(Time.now).count
    new_upgrades = Upgrading.created_on(Time.now).count
    percent_pro = (User.where(is_pro: true).count.to_f / User.count.to_f) * 100
    Stat.create(new_users: new_users, new_upgrades: new_upgrades, percent_pro: percent_pro)
  end
end
