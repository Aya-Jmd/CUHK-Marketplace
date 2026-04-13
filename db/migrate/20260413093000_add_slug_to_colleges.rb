class AddSlugToColleges < ActiveRecord::Migration[8.1]
  def up
    add_column :colleges, :slug, :string unless column_exists?(:colleges, :slug)

    say_with_time "Backfilling college slugs" do
      College.reset_column_information

      College.find_each do |college|
        next if college.slug.present?

        college.update_columns(
          slug: college.name.to_s.parameterize.delete_suffix("-college"),
          updated_at: Time.current
        )
      end
    end

    change_column_null :colleges, :slug, false
    add_index :colleges, :slug, unique: true unless index_exists?(:colleges, :slug)
  end

  def down
    remove_index :colleges, :slug if index_exists?(:colleges, :slug)
    remove_column :colleges, :slug if column_exists?(:colleges, :slug)
  end

  class College < ApplicationRecord
    self.table_name = "colleges"
  end
end
