require "rails_helper"
require "openapi_helper"

RSpec.describe "Discounts API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/discounts" do
    get "List discounts" do
      tags "Discounts"
      operationId "listDiscounts"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns discounts for the current project" do
        schema type: :object, properties: {
          discounts: { type: :array, items: Schemas::Discount },
          meta: {
            type: :object,
            properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } }
          }
        }

        before { create(:discount, project: api_key.project) }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["discounts"]).not_to be_empty
        end
      end
    end

    post "Create a discount" do
      tags "Discounts"
      operationId "createDiscount"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::DiscountCreateRequest }
      }

      response 201, "discount created" do
        schema Schemas::Discount
        let(:campaign) { create(:campaign, project: api_key.project) }
        let(:request_body) do
          {
            kind: "promotion",
            key: "spec-promo-#{SecureRandom.hex(4)}",
            name: "Spec promo",
            campaign_id: campaign.public_id,
            promotion: { active_from: "2026-01-01T00:00:00Z" },
            effects: [
              { effect_type: "percentage_off", scope: "cart", config: { percentage: 10 } }
            ]
          }
        end

        run_test!
      end

      response 422, "validation error" do
        schema Schemas::Error
        let(:request_body) { { kind: "promotion" } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/discounts/{id}" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    get "Show a discount" do
      tags "Discounts"
      operationId "getDiscount"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the discount" do
        schema Schemas::Discount
        let(:id) { create(:discount, project: api_key.project).public_id }

        run_test!
      end

      response 404, "not found" do
        schema Schemas::Error
        let(:id) { "disc_nonexistent" }

        run_test!
      end
    end

    patch "Update a discount" do
      tags "Discounts"
      operationId "updateDiscount"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: { type: :object, properties: { name: { type: :string } } } }
      }

      response 200, "discount updated" do
        schema Schemas::Discount
        let(:id) { create(:discount, project: api_key.project).public_id }
        let(:request_body) { { name: "Renamed" } }

        run_test!
      end
    end

    delete "Delete a discount" do
      tags "Discounts"
      operationId "deleteDiscount"
      security [{ BearerAuth: [] }]

      response 204, "discount deleted" do
        let(:id) { create(:discount, project: api_key.project).public_id }

        run_test!
      end
    end
  end
end
