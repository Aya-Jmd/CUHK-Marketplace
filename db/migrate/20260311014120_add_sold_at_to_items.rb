class AddSoldAtToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :sold_at, :datetime
  end
end
