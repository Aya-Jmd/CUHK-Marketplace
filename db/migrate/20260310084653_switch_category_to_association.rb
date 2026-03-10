class SwitchCategoryToAssociation < ActiveRecord::Migration[8.1]
  class MigrationItem < ApplicationRecord
    self.table_name = "items"
  end

  class MigrationCategory < ApplicationRecord
    self.table_name = "categories"
  end

  def up
    add_reference :items, :category, null: true, foreign_key: true unless column_exists?(:items, :category_id)

    MigrationItem.reset_column_information

    if column_exists?(:items, :category)
      MigrationItem.find_each do |item|
        next if item[:category].blank?

        category = MigrationCategory.find_by(name: item[:category])
        item.update_column(:category_id, category.id) if category
      end

      remove_column :items, :category, :string
    end
  end

  def down
    add_column :items, :category, :string unless column_exists?(:items, :category)

    MigrationItem.reset_column_information

    if column_exists?(:items, :category_id)
      MigrationItem.find_each do |item|
        next if item[:category_id].blank?

        category = MigrationCategory.find_by(id: item[:category_id])
        item.update_column(:category, category.name) if category
      end

      remove_reference :items, :category, foreign_key: true
    end
  end
end
