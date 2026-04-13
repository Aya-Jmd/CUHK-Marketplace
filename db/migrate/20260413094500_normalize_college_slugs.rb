class NormalizeCollegeSlugs < ActiveRecord::Migration[8.1]
  class College < ApplicationRecord
    self.table_name = "colleges"
  end

  def up
    say_with_time "Normalizing college slugs" do
      College.reset_column_information

      College.find_each do |college|
        desired_slug = college.name.to_s.parameterize
        next if desired_slug.blank? || college.slug == desired_slug

        college.update_columns(slug: desired_slug, updated_at: Time.current)
      end
    end
  end

  def down
    say_with_time "Restoring shortened college slugs" do
      College.reset_column_information

      College.find_each do |college|
        shortened_slug = college.name.to_s.parameterize.delete_suffix("-college")
        next if shortened_slug.blank? || college.slug == shortened_slug

        college.update_columns(slug: shortened_slug, updated_at: Time.current)
      end
    end
  end
end
