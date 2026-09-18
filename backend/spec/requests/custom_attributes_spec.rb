require "rails_helper"
require "openapi_helper"

RSpec.describe "Custom Attributes API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/custom_attributes" do
    get "List custom attributes" do
      tags "Custom Attributes"
      operationId "listCustomAttributes"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns custom attributes for the current project" do
        schema type: :object, properties: {
          custom_attributes: { type: :array, items: Schemas::CustomAttribute },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { create(:custom_attribute, project: api_key.project) }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["custom_attributes"]).not_to be_empty
        end
      end

      response 200, "filters by entity" do
        schema type: :object, properties: {
          custom_attributes: { type: :array, items: Schemas::CustomAttribute },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          create(:custom_attribute, project: api_key.project, entity: "cart", key: "cart_key")
          create(:custom_attribute, project: api_key.project, entity: "customer", key: "customer_key")
        end

        let(:Authorization) { "Bearer #{api_key.raw_token}" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["custom_attributes"].map { |a| a["entity"] }.uniq).to eq(["cart"])
        end
      end
    end

    post "Create a custom attribute" do
      tags "Custom Attributes"
      operationId "createCustomAttribute"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::CustomAttributeCreateRequest }
      }

      response 201, "attribute created" do
        schema Schemas::CustomAttribute
        let(:request_body) { { entity: "cart", key: "loyalty_tier", data_type: "string" } }

        run_test!
      end

      response 422, "duplicate entity+key" do
        schema Schemas::Error
        before { create(:custom_attribute, project: api_key.project, entity: "cart", key: "loyalty_tier") }
        let(:request_body) { { entity: "cart", key: "loyalty_tier", data_type: "string" } }

        run_test!
      end

      response 422, "invalid data_type" do
        schema Schemas::Error
        let(:request_body) { { entity: "cart", key: "loyalty_tier", data_type: "bogus" } }

        run_test!
      end

      response 403, "not a write role" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:request_body) { { entity: "cart", key: "loyalty_tier", data_type: "string" } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/custom_attributes/{id}" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    delete "Delete a custom attribute" do
      tags "Custom Attributes"
      operationId "deleteCustomAttribute"
      security [{ BearerAuth: [] }]

      response 204, "attribute deleted" do
        let(:id) { create(:custom_attribute, project: api_key.project).public_id }

        run_test!
      end

      response 404, "not found" do
        schema Schemas::Error
        let(:id) { "attr_nonexistent" }

        run_test!
      end
    end
  end
end
