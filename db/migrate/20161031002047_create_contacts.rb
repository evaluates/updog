class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :params
      t.references :site

      t.timestamps
    end
  end
end
