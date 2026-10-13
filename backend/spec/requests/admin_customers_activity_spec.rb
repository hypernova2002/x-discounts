# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Customers Activity API", type: :request do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }
  let(:customer) { create(:customer, project: project) }

  describe "GET /api/v1/admin/customers/:id/activity" do
    it "returns events ordered most-recent-first with their snapshotted payload" do
      CustomerActivityEvent.record!(customer: customer, type: "order", occurred_at: 2.days.ago,
                                     payload: { order_id: "ord_1", total_amount: "10.0", total_discount_amount: "0.0",
                                                total_points_earned: 5, total_points_redeemed: 0 })
      CustomerActivityEvent.record!(customer: customer, type: "gift_shop_redemption", occurred_at: 1.day.ago,
                                     payload: { item_name: "Mug", quantity: 1, points_spent: 20 })

      get "/api/v1/admin/customers/#{customer.public_id}/activity", headers: headers
      body = JSON.parse(response.body)

      expect(body["activity"].map { |e| e["type"] }).to eq(%w[gift_shop_redemption order])
      expect(body["activity"].first["item_name"]).to eq("Mug")
      expect(body["activity"].last["order_id"]).to eq("ord_1")
    end

    it "paginates instead of returning everything" do
      3.times { |i| CustomerActivityEvent.record!(customer: customer, type: "gift_shop_redemption", occurred_at: i.days.ago, payload: {}) }

      get "/api/v1/admin/customers/#{customer.public_id}/activity", params: { per_page: 2 }, headers: headers
      body = JSON.parse(response.body)

      expect(body["activity"].size).to eq(2)
      expect(body["meta"]).to eq({ "page" => 1, "pages" => 2, "count" => 3 })
    end

    it "only returns events for the requested customer" do
      other_customer = create(:customer, project: project)
      CustomerActivityEvent.record!(customer: other_customer, type: "gift_shop_redemption", occurred_at: Time.now.utc, payload: {})

      get "/api/v1/admin/customers/#{customer.public_id}/activity", headers: headers
      body = JSON.parse(response.body)

      expect(body["activity"]).to eq([])
    end
  end
end
