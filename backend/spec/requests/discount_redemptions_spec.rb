require "rails_helper"
require "openapi_helper"

RSpec.describe "Discount Redemptions API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }

  path "/api/v1/discounts/redeem" do
    post "Redeem applicable discounts and record an order" do
      tags "Discount Redemptions"
      operationId "redeemDiscounts"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::DiscountValidationRequest }
      }

      response 201, "creates an order and applies eligible discounts, creating the customer if new" do
        schema Schemas::Order

        before do
          discount = create(:discount, project: project, kind: "promotion", key: "sitewide10")
          create(:promotion, discount: discount, active_from: 1.year.ago)
          create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 10 })
        end

        let(:request_body) do
          { customer: { external_id: "new-customer" }, line_items: [{ sku: "X", quantity: 1, unit_price: 100 }] }
        end

        run_test! do
          body = JSON.parse(response.body)
          expect(body["total_discount_amount"]).to eq("10.0")
          expect(Customer.where(project_id: project.id, external_id: "new-customer")).to exist
        end
      end

      response 201, "a coupon past its redemption limit doesn't block the order" do
        schema Schemas::Order

        before do
          discount = create(:discount, project: project, kind: "coupon", key: "onlyonce", max_redemptions: 1)
          create(:coupon, discount: discount, project: project, code: "ONLYONCE")
          create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 10 })

          existing_customer = create(:customer, project: project)
          existing_order = create(:order, project: project, customer: existing_customer)
          create(:order_discount, order: existing_order, discount: discount, kind: "coupon", amount_off: 10)
        end

        let(:request_body) do
          { customer: { external_id: "another-customer" }, coupon_codes: ["ONLYONCE"], line_items: [{ sku: "X", quantity: 1, unit_price: 100 }] }
        end

        run_test! do
          body = JSON.parse(response.body)
          expect(body["total_discount_amount"]).to eq("0.0")
          expect(body["coupons"]).to eq([{ "code" => "ONLYONCE", "valid" => false, "reason" => "redemption limit reached", "discounts" => [] }])
        end
      end
    end
  end
end
