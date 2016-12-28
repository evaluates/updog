class MoveUserTokensToIdentities < ActiveRecord::Migration
  def change
    User.all.each do |user|
      user.identities.create!(
        uid: user.uid,
        provider: user.provider,
        name: user.name,
        email: user.email,
        access_token: user.access_token,
        full_access_token: user.full_access_token
      )
    end
  end
end
