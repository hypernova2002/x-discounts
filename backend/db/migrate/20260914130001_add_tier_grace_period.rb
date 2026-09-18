# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:membership_tiers) do
      # Nullable — null means no grace period, demotion out of this tier applies
      # immediately once requirements stop being met.
      add_column :grace_period_days, "integer"
    end
    alter_table(:customers) do
      # When the customer's *current* membership_tier_id was assigned — reset on
      # every real tier change (promotion, demotion, or manual reassignment), never
      # touched otherwise. This is what the grace period is measured from.
      add_column :membership_tier_entered_at, "timestamptz"
    end
  end
end
