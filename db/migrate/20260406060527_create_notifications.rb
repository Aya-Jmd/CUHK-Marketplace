class CreateNotifications < ActiveRecord::Migration[8.1] # Your version might be slightly different
  def change
    create_table :notifications do |t|
      # Update these two lines to specify the users table
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: false, foreign_key: { to_table: :users }

      t.string :action
      t.references :notifiable, polymorphic: true, null: false
      t.datetime :read_at

      t.timestamps
    end
  end
end
