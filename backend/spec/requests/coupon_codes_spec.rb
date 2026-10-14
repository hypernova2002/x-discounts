require "rails_helper"
require "openapi_helper"

RSpec.describe "Coupon Codes API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }
  let(:discount) { create(:discount, project: project, kind: "coupon") }
  let(:discount_id) { discount.public_id }

  path "/api/v1/admin/discounts/{discount_id}/coupon_codes" do
    parameter name: :discount_id, in: :path, schema: { type: :string }, required: true

    get "List a discount's coupon codes" do
      tags "Coupon Codes"
      operationId "listCouponCodes"
      produces "application/json"
      security [{ BearerAuth: [] }]
      parameter name: :includes, in: :query, schema: { type: :string }, required: false

      response 200, "lists codes for the discount" do
        schema type: :object, properties: {
          coupon_codes: { type: :array, items: Schemas::CouponCode },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { create(:coupon, discount: discount, project: project, code: "SAVE10") }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["coupon_codes"].map { |c| c["code"] }).to eq(["SAVE10"])
        end
      end

      response 200, "includes=customer eager-loads the bound customer" do
        schema type: :object, properties: {
          coupon_codes: { type: :array, items: Schemas::CouponCode },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          customer = create(:customer, project: project, external_id: "cust-1")
          create(:coupon, discount: discount, project: project, customer: customer)
        end

        let(:includes) { "customer" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["coupon_codes"].first["customer"]["external_id"]).to eq("cust-1")
        end
      end

      response 200, "includes=redemption_count uses the bulk-stats path" do
        schema type: :object, properties: {
          coupon_codes: { type: :array, items: Schemas::CouponCode },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { create(:coupon, discount: discount, project: project) }

        let(:includes) { "redemption_count" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["coupon_codes"].first["redemption_count"]).to eq(0)
        end
      end
    end

    post "Generate coupon codes" do
      tags "Coupon Codes"
      operationId "generateCouponCodes"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]
      request_body required: true, content: { "application/json" => { schema: { type: :object } } }

      response 201, "generates a manual code" do
        schema type: :array, items: Schemas::CouponCode
        let(:request_body) { { code: "SAVE20" } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body.first["code"]).to eq("SAVE20")
        end
      end

      response 403, "not a write role" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:request_body) { { code: "SAVE20" } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/discounts/{discount_id}/coupon_codes/{id}" do
    parameter name: :discount_id, in: :path, schema: { type: :string }, required: true
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    delete "Delete a coupon code" do
      tags "Coupon Codes"
      operationId "deleteCouponCode"
      security [{ BearerAuth: [] }]

      response 204, "deletes an unredeemed code" do
        let(:id) { create(:coupon, discount: discount, project: project).public_id }
        run_test!
      end

      response 404, "unknown code" do
        schema Schemas::Error
        let(:id) { "cpn_nonexistent" }
        run_test!
      end

      response 422, "a code that's already been redeemed cannot be deleted" do
        schema Schemas::Error

        let(:id) do
          coupon_code = create(:coupon, discount: discount, project: project)
          customer = create(:customer, project: project)
          redemption = create(:redemption, coupon_code: coupon_code, discount: discount, customer: customer)
          order = create(:order, project: project, customer: customer)
          create(:order_discount, order: order, discount: discount, redemption: redemption, kind: "coupon")
          coupon_code.public_id
        end

        run_test! do
          body = JSON.parse(response.body)
          expect(body["error"]["details"]).to include(hash_including("field" => "base"))
        end
      end

      response 403, "not a write role" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:id) { create(:coupon, discount: discount, project: project).public_id }
        run_test!
      end
    end
  end
end
