class CreateClicks < ActiveRecord::Migration
  def change
    create_table :clicks do |t|
      t.json :data
      t.belongs_to :site
      t.timestamps
    end
  end
end
