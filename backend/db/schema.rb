Sequel.migration do
  change do
    create_table(:accounts) do
      primary_key :id
      column :name, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :public_id, "text", :null=>false
      
      index [:public_id], :name=>:accounts_public_id_unique, :unique=>true
    end
    
    create_table(:schema_migrations) do
      column :filename, "text", :null=>false
      
      primary_key [:filename]
    end
    
    create_table(:projects) do
      primary_key :id
      foreign_key :account_id, :accounts, :null=>false, :key=>[:id]
      column :name, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :public_id, "text", :null=>false
      column :timezone, "text", :default=>"UTC", :null=>false
      
      index [:account_id]
      index [:account_id, :name], :name=>:projects_account_id_name_unique, :unique=>true
      index [:public_id], :name=>:projects_public_id_unique, :unique=>true
    end
    
    create_table(:users) do
      primary_key :id
      foreign_key :account_id, :accounts, :null=>false, :key=>[:id]
      column :email, "text", :null=>false
      column :name, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :password_digest, "text"
      column :public_id, "text", :null=>false
      column :locale, "text", :default=>"en", :null=>false
      
      index [:account_id]
      index [:email], :unique=>true
      index [:public_id], :name=>:users_public_id_unique, :unique=>true
    end
    
    create_table(:api_keys) do
      primary_key :id
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      column :name, "text", :null=>false
      column :role, "text", :null=>false
      column :token_digest, "text", :null=>false
      column :token_last_four, "text", :null=>false
      column :last_used_at, "timestamp with time zone"
      column :revoked_at, "timestamp with time zone"
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :public_id, "text", :null=>false
      
      index [:project_id]
      index [:public_id], :name=>:api_keys_public_id_unique, :unique=>true
      index [:token_digest], :unique=>true
      index [:user_id]
    end
    
    create_table(:campaigns) do
      primary_key :id
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      column :name, "text", :null=>false
      column :enabled, "boolean", :default=>true, :null=>false
      column :valid_from, "timestamp with time zone"
      column :valid_until, "timestamp with time zone"
      column :public_id, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :archived, "boolean", :default=>false, :null=>false
      
      index [:project_id]
      index [:public_id], :name=>:campaigns_public_id_unique, :unique=>true
    end
    
    create_table(:custom_attributes) do
      primary_key :id
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      column :entity, "text", :null=>false
      column :key, "text", :null=>false
      column :data_type, "text", :null=>false
      column :public_id, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      
      index [:project_id, :entity, :key], :name=>:custom_attributes_project_entity_key_unique, :unique=>true
      index [:project_id]
      index [:public_id], :name=>:custom_attributes_public_id_unique, :unique=>true
    end
    
    create_table(:gift_shop_items) do
      primary_key :id
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      column :name, "text", :null=>false
      column :description, "text"
      column :points_cost, "integer", :null=>false
      column :stock, "integer"
      column :enabled, "boolean", :default=>true, :null=>false
      column :photo_filename, "text"
      column :photo_content_type, "text"
      column :photo_byte_size, "bigint"
      column :public_id, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      
      index [:project_id]
      index [:public_id], :name=>:gift_shop_items_public_id_unique, :unique=>true
    end
    
    create_table(:membership_schemes) do
      primary_key :id
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      column :name, "text", :null=>false
      column :public_id, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      
      index [:project_id]
      index [:public_id], :name=>:membership_schemes_public_id_unique, :unique=>true
    end
    
    create_table(:project_memberships) do
      primary_key :id
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      column :role, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :public_id, "text", :null=>false
      
      index [:project_id, :user_id], :unique=>true
      index [:public_id], :name=>:project_memberships_public_id_unique, :unique=>true
      index [:user_id]
    end
    
    create_table(:sessions) do
      primary_key :id
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      column :token_digest, "text", :null=>false
      column :expires_at, "timestamp with time zone", :null=>false
      column :last_used_at, "timestamp with time zone"
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      
      index [:token_digest], :unique=>true
      index [:user_id]
    end
    
    create_table(:discounts) do
      primary_key :id
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      column :kind, "text", :null=>false
      column :name, "text", :null=>false
      column :stackable, "boolean", :default=>false, :null=>false
      column :eligibility_condition, "jsonb", :default=>Sequel::LiteralString.new("'{}'::jsonb"), :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :key, "text", :null=>false
      column :public_id, "text", :null=>false
      column :max_redemptions_per_day, "integer"
      column :max_redemption_amount, "numeric"
      column :max_redemption_amount_per_day, "numeric"
      column :max_redemption_amount_per_customer, "numeric"
      column :max_redemptions, "integer"
      column :max_redemptions_per_customer, "integer"
      foreign_key :campaign_id, :campaigns, :null=>false, :key=>[:id]
      column :refundable, "boolean", :default=>true, :null=>false
      column :kind_config, "jsonb", :default=>Sequel::LiteralString.new("'{}'::jsonb"), :null=>false
      column :enabled, "boolean", :default=>true, :null=>false
      
      index [:campaign_id]
      index [:project_id]
      index [:project_id, :key], :name=>:discounts_project_id_key_unique, :unique=>true
      index [:public_id], :name=>:discounts_public_id_unique, :unique=>true
    end
    
    create_table(:membership_tiers) do
      primary_key :id
      foreign_key :membership_scheme_id, :membership_schemes, :null=>false, :key=>[:id]
      column :name, "text", :null=>false
      column :rank, "integer", :null=>false
      column :public_id, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :requirements_condition, "jsonb", :default=>Sequel::LiteralString.new("'{}'::jsonb"), :null=>false
      column :grace_period_days, "integer"
      
      index [:membership_scheme_id]
      index [:public_id], :name=>:membership_tiers_public_id_unique, :unique=>true
      index [:membership_scheme_id, :name], :name=>:membership_tiers_scheme_name_unique, :unique=>true
      index [:membership_scheme_id, :rank], :name=>:membership_tiers_scheme_rank_unique, :unique=>true
    end
    
    create_table(:customers) do
      primary_key :id
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      column :external_id, "text", :null=>false
      column :metadata, "jsonb", :default=>Sequel::LiteralString.new("'{}'::jsonb"), :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :name, "text"
      column :email, "text"
      column :phone_number, "text"
      column :country, "text"
      column :date_of_birth, "date"
      column :marketing_opt_in, "boolean", :default=>false, :null=>false
      column :public_id, "text", :null=>false
      foreign_key :membership_tier_id, :membership_tiers, :key=>[:id], :on_delete=>:set_null
      column :membership_tier_entered_at, "timestamp with time zone"
      
      index [:membership_tier_id]
      index [:project_id, :external_id], :unique=>true
      index [:public_id], :name=>:customers_public_id_unique, :unique=>true
    end
    
    create_table(:discount_effects) do
      primary_key :id
      foreign_key :discount_id, :discounts, :null=>false, :key=>[:id]
      column :effect_type, "text", :null=>false
      column :scope, "text", :null=>false
      column :target_condition, "jsonb"
      column :config, "jsonb", :default=>Sequel::LiteralString.new("'{}'::jsonb"), :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :public_id, "text", :null=>false
      
      index [:discount_id]
      index [:public_id], :name=>:discount_effects_public_id_unique, :unique=>true
    end
    
    create_table(:discount_stacking_compatibilities) do
      primary_key :id
      foreign_key :discount_id, :discounts, :null=>false, :key=>[:id]
      foreign_key :compatible_discount_id, :discounts, :null=>false, :key=>[:id]
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      
      index [:discount_id, :compatible_discount_id], :name=>:discount_stacking_compatibilities_discount_id_compatible_discou, :unique=>true
    end
    
    create_table(:coupon_codes) do
      primary_key :id
      foreign_key :discount_id, :discounts, :null=>false, :key=>[:id]
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      foreign_key :customer_id, :customers, :key=>[:id], :on_delete=>:set_null
      column :public_id, "text", :null=>false
      column :code, "text", :null=>false
      column :max_redemptions, "integer", :default=>1, :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      
      index [:customer_id]
      index [:discount_id]
      index [:project_id, :code], :name=>:coupon_codes_project_id_code_unique, :unique=>true
      index [:public_id], :name=>:coupon_codes_public_id_unique, :unique=>true
    end
    
    create_table(:gift_shop_redemptions) do
      primary_key :id
      foreign_key :customer_id, :customers, :null=>false, :key=>[:id]
      foreign_key :gift_shop_item_id, :gift_shop_items, :key=>[:id], :on_delete=>:set_null
      column :item_name, "text", :null=>false
      column :quantity, "integer", :default=>1, :null=>false
      column :points_spent, "integer", :null=>false
      column :redeemed_at, "timestamp with time zone", :null=>false
      column :public_id, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      
      index [:customer_id]
      index [:gift_shop_item_id]
      index [:public_id], :name=>:gift_shop_redemptions_public_id_unique, :unique=>true
    end
    
    create_table(:orders) do
      primary_key :id
      foreign_key :project_id, :projects, :null=>false, :key=>[:id]
      foreign_key :customer_id, :customers, :null=>false, :key=>[:id]
      column :total_amount, "numeric", :default=>Kernel::BigDecimal("0.0"), :null=>false
      column :total_discount_amount, "numeric", :default=>Kernel::BigDecimal("0.0"), :null=>false
      column :public_id, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :cancelled_at, "timestamp with time zone"
      
      index [:customer_id]
      index [:project_id]
      index [:public_id], :name=>:orders_public_id_unique, :unique=>true
    end
    
    create_table(:order_line_items) do
      primary_key :id
      foreign_key :order_id, :orders, :null=>false, :key=>[:id]
      column :sku, "text", :null=>false
      column :quantity, "integer", :null=>false
      column :unit_price, "numeric", :null=>false
      column :metadata, "jsonb", :default=>Sequel::LiteralString.new("'{}'::jsonb"), :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      
      index [:order_id]
    end
    
    create_table(:points_redemptions) do
      primary_key :id
      foreign_key :order_id, :orders, :null=>false, :key=>[:id]
      foreign_key :customer_id, :customers, :null=>false, :key=>[:id]
      column :public_id, "text", :null=>false
      column :points_redeemed, "integer", :null=>false
      column :amount_off, "numeric", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      
      index [:customer_id]
      index [:order_id], :name=>:points_redemptions_order_id_unique, :unique=>true
      index [:public_id], :name=>:points_redemptions_public_id_unique, :unique=>true
    end
    
    create_table(:redemptions) do
      primary_key :id
      foreign_key :customer_id, :customers, :null=>false, :key=>[:id]
      column :redeemed_at, "timestamp with time zone", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      foreign_key :discount_id, :discounts, :null=>false, :key=>[:id]
      foreign_key :coupon_code_id, :coupon_codes, :null=>false, :key=>[:id]
      column :public_id, "text", :null=>false
      
      index [:coupon_code_id]
      index [:customer_id]
      index [:discount_id]
      index [:public_id], :name=>:redemptions_public_id_unique, :unique=>true
    end
    
    create_table(:loyalty_point_lots) do
      primary_key :id
      foreign_key :customer_id, :customers, :null=>false, :key=>[:id]
      foreign_key :order_id, :orders, :key=>[:id], :on_delete=>:set_null
      foreign_key :discount_id, :discounts, :key=>[:id], :on_delete=>:set_null
      column :points, "integer", :null=>false
      column :earned_at, "timestamp with time zone", :null=>false
      column :expires_at, "timestamp with time zone"
      column :public_id, "text", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :source, "text", :null=>false
      foreign_key :refund_of_points_redemption_id, :points_redemptions, :key=>[:id], :on_delete=>:set_null
      column :reason, "text"
      foreign_key :performed_by_user_id, :users, :key=>[:id], :on_delete=>:set_null
      
      index [:customer_id, :expires_at]
      index [:customer_id]
      index [:public_id], :name=>:loyalty_point_lots_public_id_unique, :unique=>true
      index [:refund_of_points_redemption_id]
    end
    
    create_table(:order_discounts) do
      primary_key :id
      foreign_key :order_id, :orders, :null=>false, :key=>[:id]
      foreign_key :discount_id, :discounts, :key=>[:id], :on_delete=>:set_null
      foreign_key :redemption_id, :redemptions, :key=>[:id], :on_delete=>:set_null
      column :kind, "text", :null=>false
      column :discount_key, "text", :null=>false
      column :discount_name, "text", :null=>false
      column :effect_type, "text", :null=>false
      column :amount_off, "numeric"
      column :free_items, "jsonb"
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :public_id, "text", :null=>false
      foreign_key :loyalty_point_lot_id, :loyalty_point_lots, :key=>[:id], :on_delete=>:set_null
      column :sku, "text"
      
      index [:discount_id]
      index [:loyalty_point_lot_id]
      index [:order_id]
      index [:public_id], :name=>:order_discounts_public_id_unique, :unique=>true
      index [:redemption_id]
    end
    
    create_table(:discount_refunds) do
      primary_key :id
      foreign_key :order_discount_id, :order_discounts, :null=>false, :key=>[:id]
      column :public_id, "text", :null=>false
      column :amount_off, "numeric", :null=>false
      column :refunded_at, "timestamp with time zone", :null=>false
      column :created_at, "timestamp with time zone", :null=>false
      column :updated_at, "timestamp with time zone", :null=>false
      column :reason, "text"
      foreign_key :performed_by_user_id, :users, :key=>[:id], :on_delete=>:set_null
      
      index [:order_discount_id]
      index [:public_id], :name=>:discount_refunds_public_id_unique, :unique=>true
    end
    
    create_table(:loyalty_point_ledger_entries) do
      primary_key :id
      foreign_key :loyalty_point_lot_id, :loyalty_point_lots, :null=>false, :key=>[:id]
      column :public_id, "text", :null=>false
      column :delta, "integer", :null=>false
      column :kind, "text", :null=>false
      foreign_key :points_redemption_id, :points_redemptions, :key=>[:id], :on_delete=>:set_null
      foreign_key :gift_shop_redemption_id, :gift_shop_redemptions, :key=>[:id], :on_delete=>:set_null
      foreign_key :order_discount_id, :order_discounts, :key=>[:id], :on_delete=>:set_null
      column :created_at, "timestamp with time zone", :null=>false
      column :reason, "text"
      foreign_key :performed_by_user_id, :users, :key=>[:id], :on_delete=>:set_null
      
      index [:gift_shop_redemption_id]
      index [:loyalty_point_lot_id]
      index [:order_discount_id]
      index [:points_redemption_id]
      index [:public_id], :name=>:loyalty_point_ledger_entries_public_id_unique, :unique=>true
    end
  end
end
              Sequel.migration do
                change do
                  self << "SET search_path TO \"$user\", public"
                  self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902050001_create_accounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902050002_create_users.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902050003_create_projects.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902050004_create_project_memberships.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902050005_create_api_keys.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902060001_create_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902060002_create_promotions.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902060003_create_coupons.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902060004_create_discount_effects.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902060005_create_discount_stacking_compatibilities.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902060006_create_customers.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902060007_create_redemptions.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260902070001_add_key_to_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260903080001_add_password_digest_to_users.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260903080002_create_sessions.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904090001_add_public_id_to_exposed_tables.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904100001_convert_timestamps_to_utc.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904110001_add_unique_index_to_projects_name.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904120001_create_custom_attributes.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904130001_add_fields_to_customers.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904130002_create_orders.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904130003_create_order_line_items.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904130004_create_order_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904140001_add_usage_limits_to_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260904150001_move_redemption_limits_to_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914070001_create_campaigns.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914070002_add_campaign_to_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914080001_create_membership_schemes.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914080002_create_membership_tiers.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914080003_add_membership_tier_to_customers.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914090001_add_loyalty_kind_to_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914090002_create_loyalties.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914090003_add_loyalty_effect_types.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914090004_add_points_to_order_discounts_and_orders.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914100001_add_points_redeemed_to_orders.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914110001_add_points_expiration_to_loyalties.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914110002_create_loyalty_point_lots.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914110003_backfill_legacy_loyalty_point_lots.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914120001_add_requirements_to_membership_tiers.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914130001_add_tier_grace_period.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914140001_create_gift_shop_items.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260914140002_create_gift_shop_redemptions.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100001_add_public_id_to_order_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100002_add_refundable_to_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100003_add_cancelled_at_to_orders.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100004_create_points_redemptions.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100005_migrate_legacy_points_redemption_order_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100006_add_loyalty_point_lot_id_to_order_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100007_add_source_to_loyalty_point_lots.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100008_create_refunds.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100009_add_refund_tracking_to_order_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100010_drop_reason_from_refunds.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100011_add_kind_config_to_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100012_drop_promotions_coupons_loyalties.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100013_drop_order_discount_refund_and_points_columns.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100014_create_discount_refunds.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100015_drop_refunds_table.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100016_create_loyalty_point_ledger_entries.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100017_update_loyalty_point_lots_for_ledger.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100018_drop_refunded_columns_from_points_redemptions.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100019_drop_points_totals_from_orders.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915100020_add_coupon_code_unique_index.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915110001_add_enabled_to_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915110002_add_audit_trail_to_refund_records.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260915110003_add_sku_to_order_discounts.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260916100001_create_coupon_codes.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260916100002_backfill_coupon_codes.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260916100003_finalize_redemption_coupon_code.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260916100004_drop_coupon_code_unique_index.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260916110001_add_coupon_code_unique_constraint.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260916120001_add_locale_to_users.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260916130001_add_archived_to_campaigns.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260916140001_add_public_id_to_redemptions.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20260919120001_add_timezone_to_projects.rb')"
                end
              end
