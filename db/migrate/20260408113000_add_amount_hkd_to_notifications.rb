class AddAmountHkdToNotifications < ActiveRecord::Migration[8.1]
  def up
    add_column :notifications, :amount_hkd, :decimal unless column_exists?(:notifications, :amount_hkd)
  end

  def down
    remove_column :notifications, :amount_hkd if column_exists?(:notifications, :amount_hkd)
  end
end
