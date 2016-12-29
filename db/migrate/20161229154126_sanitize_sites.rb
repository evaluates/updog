class SanitizeSites < ActiveRecord::Migration
  def change
    add_column :sites, :user_id, :integer, index: true
    Site.all.each do |site|
      begin
        user = User.find_by(uid: site.uid)
        site.update(user_id: user.id)
      rescue
        puts "failed to connect user to #{site.name}.updog.co"
      end
    end
    # remove_column :sites, :uid
    # remove_column :users, :provider, :string
    # remove_column :users, :name, :string
  end
end
