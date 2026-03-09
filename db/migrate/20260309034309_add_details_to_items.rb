class AddDetailsToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :category, :string
    add_column :items, :is_global, :boolean
    add_column :items, :latitude, :float
    add_column :items, :longitude, :float
    add_column :items, :user_id, :integer
    add_column :items, :college_id, :integer
  end
end
