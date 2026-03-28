class CreateOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :offers do |t|
      t.references :item, null: false, foreign_key: true
      
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      
      t.decimal :price, null: false
      t.string :status, default: "pending" # All offers start as pending!
      t.string :meetup_code

      t.timestamps
    end
  end
end