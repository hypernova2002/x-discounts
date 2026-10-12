# frozen_string_literal: true

require "rails_helper"

# Direct regression test for the bug this phase fixes: gated fields used to
# cost one (or more) extra queries per row. Asserts query count stays flat as
# row count grows, and that a field is genuinely absent when not requested.
RSpec.describe "includes= opt-in fields", type: :request do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }

  def build_discount_with_stats(campaign:, kind: "coupon")
    discount = create(:discount, project: project, campaign: campaign, kind: kind)
    return discount unless kind == "coupon"

    code = create(:coupon, discount: discount, project: project, max_redemptions: 2)
    redemption = create(:redemption, coupon_code: code, discount: discount)
    create(:order_discount, discount: discount, kind: "coupon", redemption: redemption)
    discount
  end

  describe "GET /api/v1/admin/discounts" do
    it "omits gated fields by default and includes them when requested" do
      campaign = create(:campaign, project: project)
      build_discount_with_stats(campaign: campaign)

      get "/api/v1/admin/discounts", headers: headers
      bare = JSON.parse(response.body)["discounts"].first
      expect(bare).not_to have_key("campaign")
      expect(bare).not_to have_key("redemption_count")
      expect(bare).not_to have_key("coupon_code_stats")

      get "/api/v1/admin/discounts?includes=campaign,redemption_count,coupon_code_stats", headers: headers
      full = JSON.parse(response.body)["discounts"].first
      expect(full["campaign"]).to be_present
      expect(full["redemption_count"]).to eq(1)
      expect(full["coupon_code_stats"]).to eq("total" => 1, "available" => 1)
    end

    it "keeps query count flat as the number of discounts grows" do
      campaign = create(:campaign, project: project)
      2.times { build_discount_with_stats(campaign: campaign) }

      small_count = count_queries { get "/api/v1/admin/discounts?includes=campaign,redemption_count,coupon_code_stats", headers: headers }

      10.times { build_discount_with_stats(campaign: campaign) }

      large_count = count_queries { get "/api/v1/admin/discounts?includes=campaign,redemption_count,coupon_code_stats", headers: headers }

      expect(large_count).to eq(small_count)
    end
  end

  describe "GET /api/v1/admin/campaigns" do
    it "keeps query count flat as the number of campaigns grows" do
      2.times { |i| create(:discount, project: project, campaign: create(:campaign, project: project), kind: i.even? ? "promotion" : "coupon") }

      small_count = count_queries { get "/api/v1/admin/campaigns?includes=discount_kinds", headers: headers }

      10.times { |i| create(:discount, project: project, campaign: create(:campaign, project: project), kind: i.even? ? "promotion" : "coupon") }

      large_count = count_queries { get "/api/v1/admin/campaigns?includes=discount_kinds", headers: headers }

      expect(large_count).to eq(small_count)
    end
  end

  describe "GET /api/v1/admin/customers/:id (loyalty_point_lots)" do
    def add_lot_with_activity(customer, discount:)
      order = create(:order, project: project, customer: customer)
      lot = create(:loyalty_point_lot, customer: customer, order: order, discount: discount, points: 20)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "spend", delta: -5)
    end

    it "keeps query count flat as the number of loyalty point lots grows" do
      customer = create(:customer, project: project)
      discount = create(:discount, project: project, kind: "loyalty")
      includes = "membership_tier,membership_scheme,discount_name,performed_by,status,points_remaining"

      2.times { add_lot_with_activity(customer, discount: discount) }
      # Warms Sequel's schema cache for tables only this spec touches (e.g.
      # membership_tiers) — an uncached first touch costs a few extra
      # one-time queries that would otherwise wrongly show up as "small".
      get "/api/v1/admin/customers/#{customer.public_id}?includes=#{includes}", headers: headers
      small_count = count_queries { get "/api/v1/admin/customers/#{customer.public_id}?includes=#{includes}", headers: headers }

      10.times { add_lot_with_activity(customer, discount: discount) }
      large_count = count_queries { get "/api/v1/admin/customers/#{customer.public_id}?includes=#{includes}", headers: headers }

      expect(large_count).to eq(small_count)
    end
  end
end
