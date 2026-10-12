# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Analytics API", type: :request do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }
  let(:today) { Date.today }

  def range_params(from: today - 7, to: today)
    { from: from.iso8601, to: to.iso8601 }
  end

  describe "GET /api/v1/admin/analytics/coupons" do
    it "counts a non-refunded redemption but excludes a refunded one from the series and the previous period" do
      discount = create(:discount, project: project, kind: "coupon")
      create(:order_discount, discount: discount, kind: "coupon", created_at: today)

      refunded = create(:order_discount, discount: discount, kind: "coupon", created_at: today)
      create(:discount_refund, order_discount: refunded)

      previous_period_refunded = create(:order_discount, discount: discount, kind: "coupon", created_at: today - 10)
      create(:discount_refund, order_discount: previous_period_refunded)

      get "/api/v1/admin/analytics/coupons", params: range_params, headers: headers
      body = JSON.parse(response.body)

      expect(body["summary"]["total_redemptions"]).to eq(1)
      expect(body["series"].sum { |s| s["value"] }).to eq(1)
      expect(body["previous_period"]["total_redemptions"]).to eq(0)
    end
  end

  describe "GET /api/v1/admin/analytics/promotions" do
    it "sums amount_off only for non-refunded redemptions" do
      discount = create(:discount, project: project, kind: "promotion")
      create(:order_discount, discount: discount, kind: "promotion", amount_off: 10, created_at: today)

      refunded = create(:order_discount, discount: discount, kind: "promotion", amount_off: 25, created_at: today)
      create(:discount_refund, order_discount: refunded)

      get "/api/v1/admin/analytics/promotions", params: range_params, headers: headers
      body = JSON.parse(response.body)

      expect(body["summary"]["total_discounts_from_promotions"]).to eq(10.0)
      expect(body["earnings_series"].sum { |s| s["value"] }).to eq(10.0)
    end
  end

  describe "GET /api/v1/admin/analytics/loyalty" do
    it "sums the lot's points for a plain redemption, excluding one clawed back via the ledger" do
      discount = create(:discount, project: project, kind: "loyalty")

      lot = create(:loyalty_point_lot, points: 50)
      create(:order_discount, discount: discount, kind: "loyalty", loyalty_point_lot: lot, created_at: today)

      clawed_back_lot = create(:loyalty_point_lot, points: 75)
      clawed_back_od = create(:order_discount, discount: discount, kind: "loyalty", loyalty_point_lot: clawed_back_lot, created_at: today)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: clawed_back_lot, kind: "clawback", order_discount: clawed_back_od)

      get "/api/v1/admin/analytics/loyalty", params: range_params, headers: headers
      body = JSON.parse(response.body)

      expect(body["summary"]["total_redemption_quantity"]).to eq(50.0)
      expect(body["series"].sum { |s| s["value"] }).to eq(50.0)
    end
  end

  describe "GET /api/v1/admin/analytics/orders" do
    it "counts a cancelled order in total_orders but excludes it from revenue" do
      create(:order, project: project, total_amount: 100, created_at: today)
      create(:order, project: project, total_amount: 40, created_at: today, cancelled_at: today)

      get "/api/v1/admin/analytics/orders", params: range_params, headers: headers
      body = JSON.parse(response.body)

      expect(body["summary"]["total_orders"]).to eq(2)
      expect(body["summary"]["total_revenue"]).to eq(100.0)
    end
  end

  describe "GET /api/v1/admin/analytics/customers" do
    it "counts new customers created within range" do
      create(:customer, project: project, created_at: today)
      create(:customer, project: project, created_at: today - 100)

      get "/api/v1/admin/analytics/customers", params: range_params, headers: headers
      body = JSON.parse(response.body)

      expect(body["summary"]["new_customers"]).to eq(1)
    end
  end

  describe "GET /api/v1/admin/analytics/loyalty/active_redemptions" do
    it "paginates, excludes clawed-back/expired/zero-balance lots, and filters by customer via q" do
      findable_customer = create(:customer, project: project, external_id: "findme-1")
      create(:loyalty_point_lot, customer: findable_customer, points: 40)

      other_customer = create(:customer, project: project)
      create(:loyalty_point_lot, customer: other_customer, points: 10)

      clawed_back = create(:loyalty_point_lot, customer: other_customer, points: 20)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: clawed_back, kind: "clawback", order_discount: create(:order_discount, kind: "loyalty"))

      create(:loyalty_point_lot, customer: other_customer, points: 5, expires_at: Time.now.utc - 86_400)

      spent = create(:loyalty_point_lot, customer: other_customer, points: 5)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: spent, kind: "spend", delta: -5)

      get "/api/v1/admin/analytics/loyalty/active_redemptions", params: { per_page: 1 }, headers: headers
      body = JSON.parse(response.body)

      expect(body["meta"]["count"]).to eq(2)
      expect(body["active_redemptions"].size).to eq(1)

      get "/api/v1/admin/analytics/loyalty/active_redemptions", params: { q: "findme" }, headers: headers
      filtered = JSON.parse(response.body)

      expect(filtered["active_redemptions"].size).to eq(1)
      expect(filtered["active_redemptions"].first["customer"]["external_id"]).to eq("findme-1")
      expect(filtered["active_redemptions"].first["quantity"]).to eq(40)
    end
  end

  describe "GET /api/v1/admin/analytics/attention" do
    it "includes a campaign/discount ending just inside the window and excludes ones outside it or with no end date" do
      now = Time.now.utc
      soon_campaign = create(:campaign, project: project, enabled: true, archived: false, valid_until: now + (5 * 24 * 60 * 60))
      create(:campaign, project: project, enabled: true, archived: false, valid_until: now + (30 * 24 * 60 * 60))
      create(:campaign, project: project, enabled: true, archived: false, valid_until: nil)

      soon_coupon = create(:discount, project: project, campaign: soon_campaign, kind: "coupon", enabled: true,
                                       kind_config: { valid_until: (now + (3 * 24 * 60 * 60)).iso8601 })
      create(:discount, project: project, campaign: soon_campaign, kind: "promotion", enabled: true,
                         kind_config: { active_until: (now + (30 * 24 * 60 * 60)).iso8601 })

      get "/api/v1/admin/analytics/attention", headers: headers
      body = JSON.parse(response.body)

      expect(body["campaigns"].map { |c| c["id"] }).to eq([soon_campaign.public_id])
      expect(body["discounts"].map { |d| d["id"] }).to eq([soon_coupon.public_id])
    end
  end

  describe "date range cap" do
    it "rejects a range wider than 366 days" do
      get "/api/v1/admin/analytics/orders", params: range_params(from: today - 400, to: today), headers: headers

      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["error"]["details"]).to include(hash_including("message" => a_string_matching(/366 days/)))
    end

    it "accepts a range of exactly 366 days" do
      get "/api/v1/admin/analytics/orders", params: range_params(from: today - 365, to: today), headers: headers

      expect(response.status).to eq(200)
    end
  end
end
