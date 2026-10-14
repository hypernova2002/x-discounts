require "rails_helper"
require "openapi_helper"

RSpec.describe "Order Discounts API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }
  let(:order) { create(:order, project: project) }

  path "/api/v1/admin/order_discounts/{id}/refund" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    post "Refund an order discount line" do
      tags "Order Discounts"
      operationId "refundOrderDiscount"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]
      request_body required: true, content: { "application/json" => { schema: { type: :object } } }

      response 201, "refunds the full remaining amount_off" do
        schema Schemas::RefundResult
        let(:id) { create(:order_discount, order: order, kind: "coupon", amount_off: 10).public_id }
        let(:request_body) { {} }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["amount_off"].to_f).to eq(10.0)
        end
      end

      response 404, "an id belonging to another project" do
        schema Schemas::Error
        let(:other_order) { create(:order) }
        let(:id) { create(:order_discount, order: other_order, kind: "coupon", amount_off: 10).public_id }
        let(:request_body) { {} }

        run_test!
      end

      response 422, "nothing left to refund" do
        schema Schemas::Error
        let(:id) do
          order_discount = create(:order_discount, order: order, kind: "coupon", amount_off: 10)
          Refunds::CreateService.new(order_discount: order_discount).call
          order_discount.public_id
        end
        let(:request_body) { {} }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["error"]["details"]).to include(hash_including("field" => "amount_off"))
        end
      end

      response 403, "not a write role" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:id) { create(:order_discount, order: order, kind: "coupon", amount_off: 10).public_id }
        let(:request_body) { {} }

        run_test!
      end
    end
  end
end
