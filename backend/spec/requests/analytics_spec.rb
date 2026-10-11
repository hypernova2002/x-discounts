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
