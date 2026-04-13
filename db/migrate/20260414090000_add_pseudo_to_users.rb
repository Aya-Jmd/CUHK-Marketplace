class AddPseudoToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :pseudo, :string

    execute <<~SQL
      UPDATE users
      SET pseudo = LEFT(split_part(email, '@', 1), 15)
      WHERE pseudo IS NULL OR pseudo = '';
    SQL

    change_column_null :users, :pseudo, false
    add_check_constraint :users, "char_length(pseudo) <= 15", name: "users_pseudo_max_length"
  end

  def down
    remove_check_constraint :users, name: "users_pseudo_max_length"
    remove_column :users, :pseudo
  end
end
