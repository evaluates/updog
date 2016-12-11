class AddPriceToUpgradings < ActiveRecord::Migration
  def change
    add_column :upgradings, :price, :float
  end
end
