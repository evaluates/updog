class SanitizeSites < ActiveRecord::Migration
  def change
    add_column :sites, :user_id, :integer, index: true
    Site.all.each do |site|
      begin
      site.update(user_id: site.user.id)
      rescue => e
        p e
      end
    end
    remove_column :sites, :uid
  end
end
