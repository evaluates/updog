class AddDateToStats < ActiveRecord::Migration
  def change
    add_column :stats, :date, :datetime
    Stat.all.each do |stat|
      stat.date = stat.created_at.beginning_of_day
      stat.save
    end
  end
end
