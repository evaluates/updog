class ConvertUidToStrings < ActiveRecord::Migration
  def change
    change_column :identities, :uid, :string
  end
end
