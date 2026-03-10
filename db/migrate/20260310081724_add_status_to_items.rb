class AddStatusToItems < ActiveRecord::Migration[8.1]
  def change
    # Adding default: "available" ensures old and new items don't crash the search!
    add_column :items, :status, :string, default: "available", null: false
  end
end