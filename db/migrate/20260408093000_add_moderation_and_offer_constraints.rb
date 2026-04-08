class AddModerationAndOfferConstraints < ActiveRecord::Migration[8.1]
  def up
    create_table :item_reports do |t|
      t.references :item, null: false, foreign_key: true
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.text :message, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :item_reports, :status

    add_column :users, :banned_at, :datetime
    add_reference :users, :banned_by, foreign_key: { to_table: :users }

    deduplicate_offers!
    add_index :offers, [ :item_id, :buyer_id ], unique: true
  end

  def down
    remove_index :offers, [ :item_id, :buyer_id ]
    remove_reference :users, :banned_by, foreign_key: { to_table: :users }
    remove_column :users, :banned_at
    remove_index :item_reports, :status
    drop_table :item_reports
  end

  private

  def deduplicate_offers!
    execute <<~SQL
      WITH ranked_offers AS (
        SELECT
          id,
          FIRST_VALUE(id) OVER (
            PARTITION BY item_id, buyer_id
            ORDER BY
              CASE status
                WHEN 'completed' THEN 5
                WHEN 'accepted' THEN 4
                WHEN 'pending' THEN 3
                WHEN 'failed' THEN 2
                WHEN 'declined' THEN 1
                ELSE 0
              END DESC,
              updated_at DESC,
              created_at DESC,
              id DESC
          ) AS keeper_id,
          ROW_NUMBER() OVER (
            PARTITION BY item_id, buyer_id
            ORDER BY
              CASE status
                WHEN 'completed' THEN 5
                WHEN 'accepted' THEN 4
                WHEN 'pending' THEN 3
                WHEN 'failed' THEN 2
                WHEN 'declined' THEN 1
                ELSE 0
              END DESC,
              updated_at DESC,
              created_at DESC,
              id DESC
          ) AS row_number
        FROM offers
      )
      UPDATE notifications
      SET notifiable_id = ranked_offers.keeper_id
      FROM ranked_offers
      WHERE notifications.notifiable_type = 'Offer'
        AND notifications.notifiable_id = ranked_offers.id
        AND ranked_offers.row_number > 1;
    SQL

    execute <<~SQL
      DELETE FROM offers
      WHERE id IN (
        SELECT id
        FROM (
          SELECT
            id,
            ROW_NUMBER() OVER (
              PARTITION BY item_id, buyer_id
              ORDER BY
                CASE status
                  WHEN 'completed' THEN 5
                  WHEN 'accepted' THEN 4
                  WHEN 'pending' THEN 3
                  WHEN 'failed' THEN 2
                  WHEN 'declined' THEN 1
                  ELSE 0
                END DESC,
                updated_at DESC,
                created_at DESC,
                id DESC
            ) AS row_number
          FROM offers
        ) duplicate_offers
        WHERE duplicate_offers.row_number > 1
      );
    SQL
  end
end
