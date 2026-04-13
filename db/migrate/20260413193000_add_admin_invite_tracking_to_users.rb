class AddAdminInviteTrackingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :invited_by, foreign_key: { to_table: :users }
    add_column :users, :invite_pin_ciphertext, :text
  end
end
