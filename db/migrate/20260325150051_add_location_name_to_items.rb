class AddLocationNameToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :location_name, :string
  end
end
