namespace :summary do
  desc "Send a daily summary of new sites and users"
  task send: :environment do
    ContactMailer.daily_summary.deliver_now!
  end
end
namespace :request_count do
  desc "Count number of requests"
  task write: :environment do
    fpath = Rails.root.join('tmp/request-count.txt')
    before = File.read(fpath).to_i
    after = before + Click.all.count
    File.write(Rails.root.join('tmp/request-count.txt'),after)
    Click.destroy_all
  end
end
namespace :stats do
  desc "Collect Stats"
  task collect: :environment do
    new_users = User.created_on(Time.now).count
    new_upgrades = Upgrading.created_on(Time.now).count
    percent_pro = (User.where(is_pro: true).count.to_f / User.count.to_f) * 100
    Stat.create!(new_users: new_users, new_upgrades: new_upgrades, percent_pro: percent_pro, date: Time.now.beginning_of_day)
  end
  desc "Collect Old Stats"
  task retro: :environment do
    time = Date.parse("2016-10-15")
    Stat.destroy_all
    while time < Time.now
      p time
      time += 1.day
      new_users = User.created_on(time).count
      new_upgrades = Upgrading.created_on(time).count
      users = User.where('created_at < ?', time)
      percent_pro = (users.where(is_pro: true).count.to_f / users.count.to_f) * 100
      Stat.create(new_users: new_users, new_upgrades: new_upgrades, percent_pro: percent_pro, date: time.beginning_of_day)
    end
  end
end
