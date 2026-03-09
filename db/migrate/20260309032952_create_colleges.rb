class CreateColleges < ActiveRecord::Migration[8.1]
  def change
    create_table :colleges do |t|
      t.string :name
      t.integer :listing_expiry_days

      t.timestamps
    end
  end
end
