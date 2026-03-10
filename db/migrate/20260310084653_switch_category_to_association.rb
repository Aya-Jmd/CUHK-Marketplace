class SwitchCategoryToAssociation < ActiveRecord::Migration[8.1]
  def change
    # 1. Remove the old text box column we made earlier
    remove_column :items, :category, :string

    # 2. Add the proper integer link to Aya's Category table
    add_reference :items, :category, foreign_key: true
  end
end