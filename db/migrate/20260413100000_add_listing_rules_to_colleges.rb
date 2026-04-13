class AddListingRulesToColleges < ActiveRecord::Migration[8.1]
  def change
    add_column :colleges, :max_items_per_user, :integer, null: false, default: 30
    add_column :colleges, :max_item_price, :decimal, null: false, default: 9_999_999
  end
end
