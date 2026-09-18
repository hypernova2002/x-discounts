# frozen_string_literal: true

require "securerandom"

# Campaigns are required going forward, so every existing discount needs one. Each
# project with existing discounts gets a single "Legacy" campaign (enabled, no valid
# window — i.e. always active) that its discounts are backfilled onto, preserving
# their current behavior exactly.
Sequel.migration do
  up do
    alter_table(:discounts) do
      add_foreign_key :campaign_id, :campaigns
      add_index :campaign_id
    end

    from(:projects).each do |project|
      discount_ids = from(:discounts).where(project_id: project[:id]).select_map(:id)
      next if discount_ids.empty?

      now = Time.now.utc
      campaign_id = from(:campaigns).insert(
        project_id: project[:id],
        name: "Legacy",
        enabled: true,
        public_id: "camp_#{SecureRandom.alphanumeric(16).downcase}",
        created_at: now,
        updated_at: now
      )
      from(:discounts).where(id: discount_ids).update(campaign_id: campaign_id)
    end

    alter_table(:discounts) do
      set_column_not_null :campaign_id
    end
  end

  down do
    alter_table(:discounts) do
      drop_column :campaign_id
    end
  end
end
