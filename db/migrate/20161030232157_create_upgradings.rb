class CreateUpgradings < ActiveRecord::Migration
  def change
    create_table :upgradings do |t|
      t.references :user
      t.string :source
      t.timestamps
    end
  end
end
