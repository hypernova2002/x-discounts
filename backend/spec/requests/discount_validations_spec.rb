require "rails_helper"
require "openapi_helper"

RSpec.describe "Discount Validations API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }

  path "/api/v1/discounts/validate" do
    post "Validate a cart against a project's discounts" do
      tags "Discount Validations"
      operationId "validateDiscounts"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::DiscountValidationRequest }
      }

      response 200, "sitewide promotion applies to any cart" do
        schema Schemas::DiscountValidationResponse

        before do
          discount = create(:discount, project: project, kind: "promotion", key: "sitewide10")
          create(:promotion, discount: discount, active_from: 1.year.ago)
          create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 10 })
        end

        let(:request_body) do
          { line_items: [{ sku: "X", quantity: 1, unit_price: 100 }] }
        end

        run_test! do
          body = JSON.parse(response.body)
          expect(body["total_amount_off"]).to eq(10.0)
        end
      end

      response 200, "eligibility_condition restricts to matching customers only" do
        schema Schemas::DiscountValidationResponse

        before do
          discount = create(:discount, project: project, kind: "promotion", key: "gold5",
                                        eligibility_condition: { entity: "customer", key: "tier", operator: "eq", value: "gold" })
          create(:promotion, discount: discount, active_from: 1.year.ago)
          create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })
        end

        let(:request_body) do
          { customer: { external_id: "c1", tier: "silver" }, line_items: [{ sku: "X", quantity: 1, unit_price: 100 }] }
        end

        run_test! do
          body = JSON.parse(response.body)
          expect(body["applicable_discounts"]).to be_empty
        end
      end

      response 200, "valid coupon code applies and is reported valid" do
        schema Schemas::DiscountValidationResponse

        before do
          discount = create(:discount, project: project, kind: "coupon", key: "save20")
          create(:coupon, discount: discount, project: project, code: "SAVE20")
          create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 20 })
        end

        let(:request_body) do
          { coupon_code: "SAVE20", line_items: [{ sku: "X", quantity: 1, unit_price: 100 }] }
        end

        run_test! do
          body = JSON.parse(response.body)
          expect(body["coupon"]).to eq({ "code" => "SAVE20", "valid" => true, "reason" => nil })
          expect(body["total_amount_off"]).to eq(20.0)
        end
      end

      response 200, "unknown coupon code is reported invalid, not an error" do
        schema Schemas::DiscountValidationResponse

        let(:request_body) { { coupon_code: "NOPE", line_items: [{ sku: "X", quantity: 1, unit_price: 100 }] } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["coupon"]).to eq({ "code" => "NOPE", "valid" => false, "reason" => "not found" })
        end
      end
    end
  end
end
