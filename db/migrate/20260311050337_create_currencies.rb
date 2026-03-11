class CreateCurrencies < ActiveRecord::Migration[8.1]
  def change
    create_table :currencies do |t|
      t.string :code
      t.string :name
      t.string :symbol
      t.decimal :rate_from_hkd

      t.timestamps
    end
  end
end
