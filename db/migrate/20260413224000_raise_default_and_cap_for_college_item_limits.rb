class RaiseDefaultAndCapForCollegeItemLimits < ActiveRecord::Migration[8.1]
  class MigrationCollege < ApplicationRecord
    self.table_name = "colleges"
  end

  OLD_DEFAULT_MAX_ITEMS_PER_USER = 30
  NEW_DEFAULT_MAX_ITEMS_PER_USER = 100

  def up
    change_column_default :colleges, :max_items_per_user, from: OLD_DEFAULT_MAX_ITEMS_PER_USER, to: NEW_DEFAULT_MAX_ITEMS_PER_USER

    MigrationCollege.where(max_items_per_user: OLD_DEFAULT_MAX_ITEMS_PER_USER).update_all(max_items_per_user: NEW_DEFAULT_MAX_ITEMS_PER_USER)
  end

  def down
    change_column_default :colleges, :max_items_per_user, from: NEW_DEFAULT_MAX_ITEMS_PER_USER, to: OLD_DEFAULT_MAX_ITEMS_PER_USER
  end
end
