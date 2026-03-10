class AddTrgmIndexesToItems < ActiveRecord::Migration[7.0]
  def up
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    execute <<~SQL
      CREATE INDEX index_items_on_title_trgm
      ON items
      USING gin (title gin_trgm_ops);
    SQL

    execute <<~SQL
      CREATE INDEX index_items_on_description_trgm
      ON items
      USING gin (description gin_trgm_ops);
    SQL

    execute <<~SQL
      CREATE INDEX index_items_on_category_trgm
      ON items
      USING gin (category gin_trgm_ops);
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_items_on_title_trgm;"
    execute "DROP INDEX IF EXISTS index_items_on_description_trgm;"
    execute "DROP INDEX IF EXISTS index_items_on_category_trgm;"
  end
end