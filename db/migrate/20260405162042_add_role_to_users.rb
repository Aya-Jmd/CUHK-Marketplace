class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    # default: 0 ensures every existing and future user automatically becomes a standard student!
    add_column :users, :role, :integer, default: 0, null: false
  end
end
