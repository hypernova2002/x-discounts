# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Account #{n}" }
  end

  factory :user do
    account
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
  end

  factory :project do
    account
    sequence(:name) { |n| "Project #{n}" }
  end

  factory :project_membership do
    project
    user
    role { "admin" }
  end

  factory :campaign do
    project
    sequence(:name) { |n| "Campaign #{n}" }
  end

  factory :discount do
    project
    campaign { create(:campaign, project: project) }
    kind { "promotion" }
    sequence(:key) { |n| "discount-#{n}" }
    sequence(:name) { |n| "Discount #{n}" }
  end

  factory :promotion do
    discount
    active_from { 1.year.ago }
  end

  factory :coupon, class: "CouponCode" do
    discount
    project
    sequence(:code) { |n| "CODE#{n}" }
    max_redemptions { 1 }
  end

  factory :discount_effect do
    discount
    effect_type { "percentage_off" }
    scope { "cart" }
    config { { percentage: 10 } }
  end

  factory :customer do
    project
    sequence(:external_id) { |n| "customer-#{n}" }
  end

  factory :redemption do
    coupon
    customer
    redeemed_at { Time.now.utc }
  end

  factory :order do
    project
    customer
    total_amount { 0 }
    total_discount_amount { 0 }
  end

  factory :order_discount do
    order
    discount
    kind { "coupon" }
    sequence(:discount_key) { |n| "discount-key-#{n}" }
    discount_name { "Order Discount" }
    effect_type { "percentage_off" }
    amount_off { 10 }
  end

  factory :custom_attribute do
    project
    entity { "cart" }
    sequence(:key) { |n| "attribute-#{n}" }
    data_type { "string" }
  end

  factory :discount_refund do
    order_discount
    amount_off { 5 }
    refunded_at { Time.now.utc }
  end

  factory :order_line_item do
    order
    sequence(:sku) { |n| "sku-#{n}" }
    quantity { 1 }
    unit_price { 10 }
  end

  factory :points_redemption do
    order
    customer
    points_redeemed { 100 }
    amount_off { 5 }
  end

  factory :loyalty_point_lot do
    customer
    points { 100 }
    earned_at { Time.now.utc }
    source { "manual_grant" }
  end

  factory :loyalty_point_ledger_entry do
    loyalty_point_lot
    points_redemption
    delta { -10 }
    kind { "spend" }
  end

  factory :gift_shop_item do
    project
    sequence(:name) { |n| "Gift #{n}" }
    points_cost { 100 }
  end

  factory :gift_shop_redemption do
    customer
    gift_shop_item
    sequence(:item_name) { |n| "Gift #{n}" }
    quantity { 1 }
    points_spent { 100 }
    redeemed_at { Time.now.utc }
  end

  factory :membership_scheme do
    project
    sequence(:name) { |n| "Scheme #{n}" }
  end

  factory :membership_tier do
    membership_scheme
    sequence(:name) { |n| "Tier #{n}" }
    sequence(:rank) { |n| n }
  end

  factory :api_key do
    transient do
      account { create(:account) }
    end

    project { create(:project, account: account) }
    user { create(:user, account: account) }
    role { "admin" }
    sequence(:name) { |n| "Key #{n}" }

    to_create { |instance| instance }
    initialize_with { ApiKey.create_for(project: project, user: user, role: role, name: name) }

    # A real ApiKey is only useful alongside the membership it's meant to reflect —
    # account_admin?/admin_of_project? check live ProjectMembership, not the key's own role.
    after(:create) do |_api_key, evaluator|
      create(:project_membership, project: evaluator.project, user: evaluator.user, role: evaluator.role)
    end
  end
end
