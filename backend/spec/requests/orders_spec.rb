require "rails_helper"
require "openapi_helper"

RSpec.describe "Orders API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/orders" do
    get "List orders" do
      tags "Orders"
      operationId "listOrders"
      produces "application/json"
      security [{ BearerAuth: [] }]
      parameter name: :q, in: :query, schema: { type: :string }, required: false

      response 200, "returns orders for the current project" do
        schema type: :object, properties: {
          orders: { type: :array, items: Schemas::Order },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { create(:order, project: api_key.project) }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["orders"]).not_to be_empty
        end
      end

      response 200, "filters by q, matching the order id or the customer" do
        schema type: :object, properties: {
          orders: { type: :array, items: Schemas::Order },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        let(:matching_customer) { create(:customer, project: api_key.project, external_id: "vip-customer") }
        let!(:matching_order) { create(:order, project: api_key.project, customer: matching_customer) }

        before { create(:order, project: api_key.project) }

        let(:q) { "vip-customer" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["orders"].map { |o| o["id"] }).to eq([matching_order.public_id])
        end
      end
    end
  end
end
